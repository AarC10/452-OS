#include <cio.h>
#include <drivers/intel_8255x.h>
#include <x86/ops.h>

// Global operations structure
i8255x_ops_t i8255x_ops = {0};

// Default implementations for IO operations (can be overridden)
static uint8_t default_read_8(i8255x_device_t *dev, uint32_t reg) {
  if (dev->mode == I8255X_IO_MODE) {
    // IO port mode
    return inb(dev->io_base + reg);
  } else {
    // Memory-mapped mode
    return *((volatile uint8_t *)(dev->mem_base + reg));
  }
}

static uint16_t default_read_16(i8255x_device_t *dev, uint32_t reg) {
  if (dev->mode == I8255X_IO_MODE) {
    // IO port mode
    return inw(dev->io_base + reg);
  } else {
    // Memory-mapped mode
    return *((volatile uint16_t *)(dev->mem_base + reg));
  }
}

static uint32_t default_read_32(i8255x_device_t *dev, uint32_t reg) {
  if (dev->mode == I8255X_IO_MODE) {
    // IO port mode
    return inl(dev->io_base + reg);
  } else {
    // Memory-mapped mode
    return *((volatile uint32_t *)(dev->mem_base + reg));
  }
}

static void default_write_8(i8255x_device_t *dev, uint32_t reg, uint8_t value) {
  if (dev->mode == I8255X_IO_MODE) {
    // IO port mode
    outb(value, dev->io_base + reg);
  } else {
    // Memory-mapped mode
    *((volatile uint8_t *)(dev->mem_base + reg)) = value;
  }
}

static void default_write_16(i8255x_device_t *dev, uint32_t reg,
                             uint16_t value) {
  if (dev->mode == I8255X_IO_MODE) {
    // IO port mode
    outw(value, dev->io_base + reg);
  } else {
    // Memory-mapped mode
    *((volatile uint16_t *)(dev->mem_base + reg)) = value;
  }
}

static void default_write_32(i8255x_device_t *dev, uint32_t reg,
                             uint32_t value) {
  if (dev->mode == I8255X_IO_MODE) {
    // IO port mode
    outl(value, dev->io_base + reg);
  } else {
    // Memory-mapped mode
    *((volatile uint32_t *)(dev->mem_base + reg)) = value;
  }
}

// Helper function to wait for the command unit to become idle
static int wait_for_cu_idle(i8255x_device_t *dev) {
  uint16_t status;
  int timeout = 1000; // Arbitrary timeout value

  while (timeout > 0) {
    status = i8255x_ops.read_16(dev, I8255X_SCB_STATUS);
    if ((status & I8255X_STATUS_CUS_MASK) == I8255X_STATUS_CUS_IDLE) {
      return 0; // Success
    }
    timeout--;
  }

  return -1; // Timeout
}

// Helper function to issue a command to the NIC
static int issue_command(i8255x_device_t *dev, uint16_t command) {
  uint16_t status;

  // Check if there's a command already in progress
  status = i8255x_ops.read_16(dev, I8255X_SCB_STATUS);
  if ((status & I8255X_STATUS_CX) != 0) {
    // Acknowledge the command completion status
    i8255x_ops.write_16(dev, I8255X_SCB_STATUS, I8255X_STATUS_CX);
  }

  // Issue the command
  i8255x_ops.write_16(dev, I8255X_SCB_COMMAND, command);

  // Wait for the command to be accepted
  int timeout = 1000; // Arbitrary timeout value
  while (timeout > 0) {
    status = i8255x_ops.read_16(dev, I8255X_SCB_COMMAND);
    if (status == 0) {
      return 0; // Command accepted
    }
    timeout--;
  }

  return -1; // Timeout
}

// Default initialization function
static int default_init(i8255x_device_t *dev, uint16_t io_base, void *mem_base,
                        uint8_t irq) {
  // Initialize device structure
  if (dev == NULL) {
    return -1;
  }

  dev->io_base = io_base;
  dev->mem_base = mem_base;
  dev->irq = irq;

  // Reset the controller
  return i8255x_ops.reset(dev);
}

// Default reset function
static int default_reset(i8255x_device_t *dev) {
  uint16_t cmd;
  int result;

  // Issue a software reset command
  cmd = I8255X_CMD_RESET_MASK;
  result = issue_command(dev, cmd);
  if (result < 0) {
    cio_printf("i8255x: Reset timeout\n");
    return -1;
  }

  // Wait for reset to complete (minimum 10 microseconds)
  // In a real system, we'd use a delay function here
  int i;
  for (i = 0; i < 1000; i++) {
    // Delay loop
  }

  // Get MAC address from EEPROM
  result = i8255x_ops.get_mac_addr(dev, dev->mac_addr);
  if (result < 0) {
    cio_printf("i8255x: Failed to read MAC address\n");
    return -1;
  }

  // Initialize TX and RX buffers
  i8255x_ops.init_tx_buffers(dev);
  i8255x_ops.init_rx_buffers(dev);

  // Enable interrupts if needed
  // i8255x_ops.enable_irq(dev);

  return 0;
}

// Default MAC address read function
static int default_get_mac_addr(i8255x_device_t *dev, uint8_t *mac_addr) {
  // TODO: Read from EEPROM
  // For now, set a default MAC address (00:AA:BB:CC:DD:EE)
  mac_addr[0] = 0x00;
  mac_addr[1] = 0xAA;
  mac_addr[2] = 0xBB;
  mac_addr[3] = 0xCC;
  mac_addr[4] = 0xDD;
  mac_addr[5] = 0xEE;

  return 0;
}

// Default TX buffer initialization
static void default_init_tx_buffers(i8255x_device_t *dev) {
  // In a real implementation, would allocate memory for TX buffers
  // and set up the command chains
  dev->tx_curr = 0;
  dev->tx_packets = 0;
  dev->tx_errors = 0;

  // For now, we'll just print a placeholder message
  cio_printf("i8255x: TX buffers initialized\n");
}

// Default RX buffer initialization
static void default_init_rx_buffers(i8255x_device_t *dev) {
  // In a real implementation, would allocate memory for RX buffers
  // and set up the receive frame descriptors
  dev->rx_curr = 0;
  dev->rx_packets = 0;
  dev->rx_errors = 0;

  // For now, we'll just print a placeholder message
  cio_printf("i8255x: RX buffers initialized\n");
}

// Default transmit function (placeholder)
static int default_transmit(i8255x_device_t *dev, const uint8_t *buffer,
                            uint32_t length) {
  // For now, we'll just print a placeholder message
  cio_printf("i8255x: Transmit packet of length %d\n", length);
  dev->tx_packets++;
  return 0;
}

// Default receive function (placeholder)
static int default_receive(i8255x_device_t *dev, uint8_t *buffer,
                           uint32_t *length) {
  // For now, we'll just print a placeholder message
  cio_printf("i8255x: Receive packet\n");
  *length = 0; // No data received
  return 0;
}

// Default IRQ functions (placeholders)
static void default_enable_irq(i8255x_device_t *dev) {
  cio_printf("i8255x: IRQs enabled\n");
}

static void default_disable_irq(i8255x_device_t *dev) {
  cio_printf("i8255x: IRQs disabled\n");
}

static void default_handle_irq(i8255x_device_t *dev) {
  uint16_t status = i8255x_ops.read_16(dev, I8255X_SCB_STATUS);

  // Check for command completion
  if (status & I8255X_STATUS_CX) {
    // Acknowledge the interrupt
    i8255x_ops.write_16(dev, I8255X_SCB_STATUS, I8255X_STATUS_CX);
    cio_printf("i8255x: Command completed\n");
  }

  // Check for frame received
  if (status & I8255X_STATUS_FR) {
    // Acknowledge the interrupt
    i8255x_ops.write_16(dev, I8255X_SCB_STATUS, I8255X_STATUS_FR);
    cio_printf("i8255x: Frame received\n");

    // Process received frame(s)
    // This would call receive() in a real implementation
  }

  // Check for command unit not active
  if (status & I8255X_STATUS_CNA) {
    // Acknowledge the interrupt
    i8255x_ops.write_16(dev, I8255X_SCB_STATUS, I8255X_STATUS_CNA);
    cio_printf("i8255x: Command unit not active\n");
  }

  // Check for receive unit not ready
  if (status & I8255X_STATUS_RNR) {
    // Acknowledge the interrupt
    i8255x_ops.write_16(dev, I8255X_SCB_STATUS, I8255X_STATUS_RNR);
    cio_printf("i8255x: Receive unit not ready\n");

    // Restart the receive unit
    // issue_command(dev, I8255X_CMD_RU_START);
  }
}

// Default power management functions (placeholders)
static int default_power_up(i8255x_device_t *dev) {
  cio_printf("i8255x: Powered up\n");
  return 0;
}

static int default_power_down(i8255x_device_t *dev) {
  cio_printf("i8255x: Powered down\n");
  return 0;
}

// Initialize operations with default implementations
void i8255x_init_ops(void) {
  i8255x_ops.init = default_init;
  i8255x_ops.reset = default_reset;
  i8255x_ops.get_mac_addr = default_get_mac_addr;

  i8255x_ops.read_8 = default_read_8;
  i8255x_ops.read_16 = default_read_16;
  i8255x_ops.read_32 = default_read_32;
  i8255x_ops.write_8 = default_write_8;
  i8255x_ops.write_16 = default_write_16;
  i8255x_ops.write_32 = default_write_32;

  i8255x_ops.transmit = default_transmit;
  i8255x_ops.receive = default_receive;

  i8255x_ops.init_tx_buffers = default_init_tx_buffers;
  i8255x_ops.init_rx_buffers = default_init_rx_buffers;

  i8255x_ops.enable_irq = default_enable_irq;
  i8255x_ops.disable_irq = default_disable_irq;
  i8255x_ops.handle_irq = default_handle_irq;

  i8255x_ops.power_up = default_power_up;
  i8255x_ops.power_down = default_power_down;
}

// Set custom operation functions
void i8255x_set_ops(const i8255x_ops_t *ops) {
  if (ops != NULL) {
    // Copy all function pointers that are non-NULL
    if (ops->init)
      i8255x_ops.init = ops->init;
    if (ops->reset)
      i8255x_ops.reset = ops->reset;
    if (ops->get_mac_addr)
      i8255x_ops.get_mac_addr = ops->get_mac_addr;

    if (ops->read_8)
      i8255x_ops.read_8 = ops->read_8;
    if (ops->read_16)
      i8255x_ops.read_16 = ops->read_16;
    if (ops->read_32)
      i8255x_ops.read_32 = ops->read_32;
    if (ops->write_8)
      i8255x_ops.write_8 = ops->write_8;
    if (ops->write_16)
      i8255x_ops.write_16 = ops->write_16;
    if (ops->write_32)
      i8255x_ops.write_32 = ops->write_32;

    if (ops->transmit)
      i8255x_ops.transmit = ops->transmit;
    if (ops->receive)
      i8255x_ops.receive = ops->receive;

    if (ops->init_tx_buffers)
      i8255x_ops.init_tx_buffers = ops->init_tx_buffers;
    if (ops->init_rx_buffers)
      i8255x_ops.init_rx_buffers = ops->init_rx_buffers;

    if (ops->enable_irq)
      i8255x_ops.enable_irq = ops->enable_irq;
    if (ops->disable_irq)
      i8255x_ops.disable_irq = ops->disable_irq;
    if (ops->handle_irq)
      i8255x_ops.handle_irq = ops->handle_irq;

    if (ops->power_up)
      i8255x_ops.power_up = ops->power_up;
    if (ops->power_down)
      i8255x_ops.power_down = ops->power_down;
  }
}

// Get the current operations structure
i8255x_ops_t *i8255x_get_ops(void) { return &i8255x_ops; }

// Initialize the Intel 8255x network controller
i8255x_device_t *i8255x_init(uint16_t io_base, void *mem_base, uint8_t irq,
                             uint8_t mode) {
  // First make sure the operations are initialized
  if (i8255x_ops.init == NULL) {
    i8255x_init_ops();
  }

  // Allocate device structure
  i8255x_device_t *dev = (i8255x_device_t *)kmalloc(sizeof(i8255x_device_t));
  if (dev == NULL) {
    cio_printf("i8255x: Failed to allocate device structure\n");
    return NULL;
  }

  // Clear the device structure
  memset(dev, 0, sizeof(i8255x_device_t));

  // Set I/O mode
  dev->mode = mode;

  // Call the initialization function
  if (i8255x_ops.init(dev, io_base, mem_base, irq) < 0) {
    cio_printf("i8255x: Initialization failed\n");
    kfree(dev);
    return NULL;
  }

  cio_printf("i8255x: Initialized successfully at ");
  if (mode == I8255X_IO_MODE) {
    cio_printf("I/O port 0x%04x\n", io_base);
  } else {
    cio_printf("memory address 0x%p\n", mem_base);
  }

  cio_printf("i8255x: MAC address: %02x:%02x:%02x:%02x:%02x:%02x\n",
             dev->mac_addr[0], dev->mac_addr[1], dev->mac_addr[2],
             dev->mac_addr[3], dev->mac_addr[4], dev->mac_addr[5]);

  return dev;
}

// Shutdown the Intel 8255x network controller
void i8255x_shutdown(i8255x_device_t *dev) {
  if (dev == NULL) {
    return;
  }

  // Disable IRQs
  i8255x_ops.disable_irq(dev);

  // Issue a reset command
  issue_command(dev, I8255X_CMD_RESET_MASK);

  // Free memory
  kfree(dev);

  cio_printf("i8255x: Shutdown complete\n");
}

// Connect the network controller to the network layer
int i8255x_attach_network_layer(i8255x_device_t *dev,
                                network_layer_t *net_layer) {
  if (dev == NULL || net_layer == NULL) {
    return -1;
  }

  // Store the network layer reference
  dev->net_layer = net_layer;

  cio_printf("i8255x: Attached to network layer\n");

  return 0;
}
