#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <byteswap.h>
#include <string.h>
#include <errno.h>
#include <fcntl.h>
#include <ctype.h>
#include <sys/types.h>
#include <sys/mman.h>

// ltoh: little endian to host
// htol: host to little endian
#if __BYTE_ORDER == __LITTLE_ENDIAN
#define ltohl(x)       (x)
#define ltohs(x)       (x)
#define htoll(x)       (x)
#define htols(x)       (x)
#elif __BYTE_ORDER == __BIG_ENDIAN
#define ltohl(x)     __bswap_32(x)
#define ltohs(x)     __bswap_16(x)
#define htoll(x)     __bswap_32(x)
#define htols(x)     __bswap_16(x)
#endif

// Static configuration
#define PAGE_SIZE 256
#define SECTOR_SIZE 65536
#define DATA_BYTES_OFFSET 0x0020
#define GI_BASE 0x00000000
#define SI_BASE 0x02000000

// Uncomment the following to inject a fault in the new Golden Image, so that the configuration
// process will fall back to the Silver Image
//#define DEBUG_FALL_BACK

// Write through XDMA
void write_reg(uint32_t *addr, uint32_t data)
{
    *((uint32_t *) addr) = htoll(data);
}

// Read through XDMA
uint32_t read_reg(uint32_t *addr) 
{
    uint32_t read_result;

    read_result = *((uint32_t *) addr);
    read_result = ltohl(read_result);

    return read_result;
}

// Wait for command to end by polling the remote status register
void wait_command_end(uint32_t *addr)
{
    int flag;
    uint32_t retval;

    flag = 0;
    while(flag == 0) {
        retval = read_reg(addr);
    
        // Wait for something to be written in the status register
        if(retval != 0x00000000) {
            // Command completed
            if(retval == 0x00000001) {
                flag = 1;
            }
            else {
                flag = 2;
            }
        }
        else {
            // Wait before polling again
            usleep(10);
        }
    }
    
    if(flag != 1) {
        printf("erro: Something went wrong$\n");
        printf("erro:    Firmware Upgrade status register: 0x%08x\n", retval);
    }
}

// Main block
int main(int argc, char **argv)
{
    int fd;
    void *map;
    off_t target;
    off_t pgsz;
    off_t target_aligned;
    off_t offset;
    char *device;
    FILE *fpga_bit_file;
    uint32_t *fpga_page;
    uint32_t num_bytes_read;
    int skip_erase;
    uint32_t erase_size;
    uint32_t num_sectors_to_erase;
    uint32_t sector_0_base;
    uint32_t sector_latest_base;
    uint32_t rows_per_page;
    uint32_t sector_base;
    float perc;
    int word;
    uint32_t row_offset;
    uint32_t bram_addr;
    uint32_t page_id;
    uint32_t page_addr;
    uint32_t golden_image_num_pages;
    uint32_t image_size;
    char fpga_bit_file_name [256];

    // Keep defaults
    device = "/dev/xdma0_user";
    target = 0x00000000;

    // Sanity checks
    pgsz = sysconf(_SC_PAGESIZE);
    offset = target & (pgsz - 1);
    target_aligned = target & (~(pgsz - 1));

    // Clear all Bytes in Flash from 0x00000000 up to 0x02000000
    erase_size = SI_BASE - GI_BASE;
    num_sectors_to_erase = erase_size / SECTOR_SIZE;

    // Base address of the first sector to erase
    sector_0_base = GI_BASE;

    // Base address of the latest sector to erase
    sector_latest_base = sector_0_base + (SECTOR_SIZE * (num_sectors_to_erase - 1));

    // Number of rows per page in BRAM
    rows_per_page = PAGE_SIZE / 4;


    //---- ARGUMENTS PROCESSING -----------------------------------------------

    if(argc < 2) {
        printf("info: Usage: %s <fpga_bit_file>\n", argv[0]);
        exit(EXIT_FAILURE);
    }

    strcpy(fpga_bit_file_name, argv[1]);
    skip_erase = 0;


    //---- PREAMBLE -----------------------------------------------------------

    printf("dbug: Firmware Upgrade configuration\n");
    printf("dbug:    Page size: %d\n", PAGE_SIZE);
    printf("dbug:    Sector size: %d\n", SECTOR_SIZE);
    printf("dbug:    Pages per sector: %d\n", SECTOR_SIZE / PAGE_SIZE);
    printf("dbug:    Golden Image base: 0x%08x\n", GI_BASE);
    printf("dbug:    Silver Image base: 0x%08x\n", SI_BASE);
    printf("dbug:    Golden Image range: %d\n", erase_size);
    printf("dbug:    Number of sectors to erase: %d\n", num_sectors_to_erase);
    printf("dbug:    First sector base: 0x%08x\n", sector_0_base);
    printf("dbug:    Last sector base: 0x%08x\n", sector_latest_base);
    printf("dbug:    Number of BRAM rows per parge: %d\n", rows_per_page);

    // Map BRAM range through XDMA BARs
    if((fd = open(device, O_RDWR | O_SYNC)) == -1) {
        printf("character device %s opened failed: %s.\n", device, strerror(errno));
        return -errno;
    }

    map = mmap(NULL, offset + 4, PROT_READ | PROT_WRITE, MAP_SHARED, fd, target_aligned);
    if (map == (void *)-1) {
        printf("Memory 0x%lx mapped failed: %s.\n", target, strerror(errno));
        exit(EXIT_FAILURE);
    }

    // Adjust address
    map += offset;


    //---- ERASE FLASH SECTORS ------------------------------------------------

    if(skip_erase == 0) {
        printf("info: Erasing %d sectors\n",num_sectors_to_erase);
        printf("info:    First sector base: 0x%08x\n", sector_0_base);
        printf("info:    Last sector base: 0x%08x\n", sector_latest_base);

        for(int sdx = 0; sdx < num_sectors_to_erase; sdx++) {
            // Base address of sector to clear
            sector_base = sector_0_base + (SECTOR_SIZE * sdx);
        
            perc = (sdx + 1) * 1.0 / num_sectors_to_erase * 100;
            printf("\rinfo: Erasing sector w/ base address 0x%08x (%.1f%%)\r", sector_base, perc);
            fflush(stdout);
        
            // Avoid race conditions: enter a critical section by clearing out the status register.
            // This has to be done before the command is sent to the message box
            write_reg(map + 0x000c, 0x00000000);
        
            // Write command arguments
            write_reg(map + 0x0004, sector_base);
            write_reg(map + 0x0008, 0x00000001);
        
            // Send command
            write_reg(map + 0x0000, 0xffff1111);
        
            // Wait for command to end
            wait_command_end(map + 0x000c);
        }//end_for(sdx)
    }
    else {
        printf("warn: Skipping Flash erase\n");
    }
    printf("\n");


    //---- PROGRAM FLASH PAGES ------------------------------------------------

    // Prepare buffer for a full page
    fpga_page = malloc(sizeof(uint32_t) * PAGE_SIZE);
    if(fpga_page == NULL) {
        printf("erro: Unable to allocate memory for page (%d Bytes)\n", PAGE_SIZE);
        exit(EXIT_FAILURE);
    }

    // Read data from binary file one page at a time
    fpga_bit_file = fopen(fpga_bit_file_name, "rb");
    if(fpga_bit_file == NULL) {
        printf("erro: Cannot open binary file %s\n", fpga_bit_file_name);
        exit(EXIT_FAILURE);
    }

    // Get size of image
    fseek(fpga_bit_file, 0L, SEEK_END);
    image_size = ftell(fpga_bit_file);
    fseek(fpga_bit_file, 0L, SEEK_SET);
    golden_image_num_pages = (image_size / PAGE_SIZE) + 1;

    page_id = 0;
    do {
        num_bytes_read = fread(fpga_page, 1, PAGE_SIZE, fpga_bit_file);

        // Send page data to remote BRAM through XDMA BAR
        perc = (page_id + 1) * 1.0 / golden_image_num_pages * 100;
        printf("\rinfo: Writing %d Bytes to Flash page @0x%08x (page %d/%d, %.1f%%)\r", num_bytes_read, page_addr, page_id, golden_image_num_pages, perc);
        fflush(stdout);
        for(word = 0; word < num_bytes_read / 4; word++) {
            row_offset = word * 4;
            bram_addr = DATA_BYTES_OFFSET + row_offset;
            write_reg(map + bram_addr, fpga_page[word]);
        }//end_for(word)

        // Pad if necessary
        for(; word < PAGE_SIZE / 4; word++)  {
            row_offset = word * 4;
            bram_addr = DATA_BYTES_OFFSET + row_offset;
            write_reg(map + bram_addr, 0xffffffff);
        }//end_for(word)

#       ifdef DEBUG_FALL_BACK
        // In case of fallback test, remove last page of the image
        for(word = 0; word < PAGE_SIZE / 4; word++) {
            row_offset = word * 4;
            bram_addr = DATA_BYTES_OFFSET + row_offset;
            write_reg(map + bram_addr, 0xffffffff);
        }
#       endif /* DEBUG_FALL_BACK */

        // Clear out before programming
        write_reg(map + 0x000c, 0x00000000);

        // Write current page address
        page_addr = page_id * PAGE_SIZE;
        write_reg(map + 0x0004, page_addr);
        
        // Always write one page at a time
        write_reg(map + 0x0008, 0x00000001);
        
        // Send command
        write_reg(map + 0x0000, 0xffff2222);
        
        // Wait for command to end
        wait_command_end(map + 0x000c);

        // Ready for next page
        page_id++;
    } while(num_bytes_read > 0);

    printf("\n");
    printf("info: Golden Image has been succesfully updated\n\r");

    fclose(fpga_bit_file);
    free(fpga_page);

    map -= offset;
    if (munmap(map, offset + 4) == -1) {
        printf("Memory 0x%lx mapped failed: %s.\n", target, strerror(errno));
        exit(EXIT_FAILURE);
    }
    close(fd);

    exit(EXIT_SUCCESS);
}
