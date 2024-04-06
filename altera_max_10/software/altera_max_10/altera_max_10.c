/* 
 * "Small Hello World" example. 
 * 
 * This example prints 'Hello from Nios II' to the STDOUT stream. It runs on
 * the Nios II 'standard', 'full_featured', 'fast', and 'low_cost' example 
 * designs. It requires a STDOUT  device in your system's hardware. 
 *
 * The purpose of this example is to demonstrate the smallest possible Hello 
 * World application, using the Nios II HAL library.  The memory footprint
 * of this hosted application is ~332 bytes by default using the standard 
 * reference design.  For a more fully featured Hello World application
 * example, see the example titled "Hello World".
 *
 * The memory footprint of this example has been reduced by making the
 * following changes to the normal "Hello World" example.
 * Check in the Nios II Software Developers Manual for a more complete 
 * description.
 * 
 * In the SW Application project (small_hello_world):
 *
 *  - In the C/C++ Build page
 * 
 *    - Set the Optimization Level to -Os
 * 
 * In System Library project (small_hello_world_syslib):
 *  - In the C/C++ Build page
 * 
 *    - Set the Optimization Level to -Os
 * 
 *    - Define the preprocessor option ALT_NO_INSTRUCTION_EMULATION 
 *      This removes software exception handling, which means that you cannot 
 *      run code compiled for Nios II cpu with a hardware multiplier on a core 
 *      without a the multiply unit. Check the Nios II Software Developers 
 *      Manual for more details.
 *
 *  - In the System Library page:
 *    - Set Periodic system timer and Timestamp timer to none
 *      This prevents the automatic inclusion of the timer driver.
 *
 *    - Set Max file descriptors to 4
 *      This reduces the size of the file handle pool.
 *
 *    - Check Main function does not exit
 *    - Uncheck Clean exit (flush buffers)
 *      This removes the unneeded call to exit when main returns, since it
 *      won't.
 *
 *    - Check Don't use C++
 *      This builds without the C++ support code.
 *
 *    - Check Small C library
 *      This uses a reduced functionality C library, which lacks  
 *      support for buffering, file IO, floating point and getch(), etc. 
 *      Check the Nios II Software Developers Manual for a complete list.
 *
 *    - Check Reduced device drivers
 *      This uses reduced functionality drivers if they're available. For the
 *      standard design this means you get polled UART and JTAG UART drivers,
 *      no support for the LCD driver and you lose the ability to program 
 *      CFI compliant flash devices.
 *
 *    - Check Access device drivers directly
 *      This bypasses the device file system to access device drivers directly.
 *      This eliminates the space required for the device file system services.
 *      It also provides a HAL version of libc services that access the drivers
 *      directly, further reducing space. Only a limited number of libc
 *      functions are available in this configuration.
 *
 *    - Use ALT versions of stdio routines:
 *
 *           Function                  Description
 *        ===============  =====================================
 *        alt_printf       Only supports %s, %x, and %c ( < 1 Kbyte)
 *        alt_putstr       Smaller overhead than puts with direct drivers
 *                         Note this function doesn't add a newline.
 *        alt_putchar      Smaller overhead than putchar with direct drivers
 *        alt_getchar      Smaller overhead than getchar with direct drivers
 *
 */

#include "sys/alt_stdio.h"
#include <stdio.h>
#include <stdbool.h>
#include "altera_avalon_pio_regs.h"
#include "system.h"

bool newValue(int, int*, size_t);
void readOnboardMem();
int return_addr(int);
void readAllMem();
void print_data(int, int);

#define ETH_MEM_BASE 0 

int main()
{ 
  //int *all_seen_switch_values;
  alt_putstr("\n\n ----- Starting main ----- \n\n");

  readAllMem();

  alt_putstr("\n\n ----- All done -----\n");
  return 0;
}

void readAllMem(){
  int ethernet_line;
  int eth_offset = 0;
  int print_count = 0;
  int between_delimiters = 1;
  
  eth_offset = 0;
  print_count = 0;
  alt_printf("\nReading the next span ...\n");
  while (eth_offset < ONCHIP_MEMORY_SPAN) {
    ethernet_line = IORD_32DIRECT(ONCHIP_MEMORY_BASE, eth_offset);
    if (ethernet_line != 0) {
      // look for the delimiter
      //if (ethernet_line == 0xAAAAAAAA) {
      //  alt_printf("\nFound the delimiter, going to start printing!\n");
      //  between_delimiters = (between_delimiters == 1) ? 0 : 1;
      //} else if (between_delimiters == 1) { 
        print_data(ONCHIP_MEMORY_BASE+eth_offset, ethernet_line);
        print_count++;
      //}
    }
    if (print_count == 8) {
      alt_printf("\n");
      print_count = 0;
      usleep(10000);
    }
    eth_offset+=4;
  }
}

int return_addr(int data){
  int ethernet_line;
  int eth_addr = 0;
  int found = 0;
  //while (eth_addr < 0xFFFF) {
  while (eth_addr < ONCHIP_MEMORY_SPAN) {
    ethernet_line = IORD_32DIRECT(ONCHIP_MEMORY_BASE, eth_addr);
    usleep(100);
    if (ethernet_line == data) {
      alt_printf("Found 'x%x, which matches 'x%x, at 'x%x.\n ", ethernet_line, data, ONCHIP_MEMORY_BASE+eth_addr);
      found = 1;
      //return ethernet_line;
    }
    if (eth_addr % 0x800000 == 0) {
      alt_printf("\nstill looking, eth_addr 'x%x ...\n", eth_addr);
    }
    eth_addr+=4;
  }
  if (found) {return data;}
  alt_printf("Couldn't find 'x%x. Returning\n", data);
  return -1;
}

// so memory print statements are nicely aligned in the Nios II Console
void print_data(int addr, int data) {
  // alt_printf can only print %c, %s, %x, and %% ... anything else will bork the print statement entirely
  alt_printf("A x'%x  ", addr);

  if (addr < 0x10) {
    alt_printf("     ");
  } else if (addr < 0x100) {
    alt_printf("    ");
  } else if (addr < 0x1000) {
    alt_printf("   ");
  } else if (addr < 0x10000) {
    alt_printf("  ");
  } else if (addr < 0x100000) {
    alt_printf(" ");
  }
  alt_printf("|  D x'%x ", data);
  if (data < 0) {
  }
  else if (data < 0x10) {
    alt_printf("       ");
  } else if (data < 0x100) {
    alt_printf("      ");
  } else if (data < 0x1000) {
    alt_printf("     ");
  } else if (data < 0x10000) {
    alt_printf("    ");
  } else if (data < 0x100000) {
    alt_printf("   ");
  } else if (data < 0x1000000) {
    alt_printf("  ");
  } else if (data < 0x10000000) {
    alt_printf(" ");
  }
  alt_printf(" || ");
}

// at eth_addr 'x1967fc8, memory line is 'xdeadbeaf
// at eth_addr 'x1967fe0, memory line is 'xdeadbeaf
// ... but then ...
// at eth_addr 'x1967fc8, memory line is 'x44bc
// at eth_addr 'x1967fe0, memory line is 'xa
void readOnboardMem() {
    // 2/14/24: DEADBEAF in (all?) the 'h???7FC8 and 'h???7fE0
  int ethernet_line;
  int addr = 0;
  //int mem_offset1 = 0x7FC8;
  //int mem_offset2 = 0x7FE0;
  int mem_offset1 = 0x7FC4;
  int mem_offset2 = 0x7FDC;

  for (int base_addr = 0x00; base_addr <= 0x400; base_addr++) {
    addr = (base_addr << 16) + mem_offset1;
    ethernet_line = IORD_32DIRECT(ETH_MEM_BASE, addr);
    if (ethernet_line == 0xDEADBEAF) {
      alt_printf("DEADBEAF at eth_addr 'x%x, memory line is 'x%x\n", addr, ethernet_line);
    } else {
      alt_printf("at eth_addr 'x%x, memory line is 'x%x\n", addr, ethernet_line);
    }
    addr = (base_addr << 16) + mem_offset2;
    ethernet_line = IORD_32DIRECT(ETH_MEM_BASE, addr);
    if (ethernet_line == 0xDEADBEAF) {
      alt_printf("DEADBEAF at eth_addr 'x%x, memory line is 'x%x\n", addr, ethernet_line);
    } else {
      alt_printf("at eth_addr 'x%x, memory line is 'x%x\n", addr, ethernet_line);
    }
  }
}

bool newValue(int val, int *arr, size_t n) {
  for(int i = 0; i < n; i++) {
    if (arr[i] == val)
      return false;
  }
  return true;
}