using System;
using System.Runtime.InteropServices;
using System.Collections.Generic;
using System.Text;
using System.Threading;
using System.Diagnostics;

public class FPGA
{
    public static int num_devices;
    public static string[] device_list;
    public static System.Diagnostics.Stopwatch watch = new System.Diagnostics.Stopwatch();
    const uint TRANSFER_MAX_INTS = 32;

    [UnmanagedFunctionPointer(CallingConvention.Cdecl)]
    unsafe delegate void CallbackPrototype(Int32 device_id, Int32 device_channel, byte command, byte payload, byte* data, byte data_size);
    static CallbackPrototype CallbackPrototypePtr;

    const string activehost_dll = "ActiveHost64.dll";
    [DllImport(activehost_dll)]
    static extern char EPT_AH_GetName();
    [DllImport(activehost_dll)]
    static extern char EPT_AH_GetVersionString();
    [DllImport(activehost_dll)]
    static extern unsafe void EPT_AH_GetVersionControl(short* v_major, short* v_minor, short* v_revision, short* v_debug);
    [DllImport(activehost_dll)]
    static extern unsafe char EPT_AH_GetInterfaceVersion();
    [DllImport(activehost_dll)]
    static extern unsafe Int32 EPT_AH_CheckCompatibility(char* version, char* interface_version);
    [DllImport(activehost_dll)]
    static extern unsafe Int32 EPT_AH_Open(void* in_display_function, void* in_progress_bar_range_function, void* in_progress_bar_value_function);
    [DllImport(activehost_dll)]
    static extern unsafe Int32 EPT_AH_Close();
    [DllImport(activehost_dll)]
    static extern unsafe bool EPT_AH_Initialize();
    [DllImport(activehost_dll)]
    static extern unsafe void EPT_AH_Release();
    [DllImport(activehost_dll)]
    static extern unsafe Int32 EPT_AH_QueryDevices();
    [DllImport(activehost_dll)]
    static extern unsafe Int32 EPT_AH_SelectActiveDeviceByName(char* device_name);
    [DllImport(activehost_dll)]
    static extern unsafe Int32 EPT_AH_SelectActiveDeviceByIndex(Int32 device_index);
    [DllImport(activehost_dll)]
    static extern unsafe char* EPT_AH_GetDeviceName(int device_index);
    [DllImport(activehost_dll)]
    static extern unsafe char* EPT_AH_GetDeviceSerial(Int32 device_index);
    [DllImport(activehost_dll)]
    static extern unsafe int EPT_AH_OpenDeviceByIndex(Int32 device_index);
    [DllImport(activehost_dll)]
    static extern unsafe int EPT_AH_OpenDeviceByName(char* name);
    [DllImport(activehost_dll)]
    static extern unsafe Int32 EPT_AH_CloseDeviceByIndex(int device_index);
    [DllImport(activehost_dll)]
    static extern unsafe Int32 EPT_AH_CloseDeviceByName(char* name);
    [DllImport(activehost_dll)]
    static extern unsafe Int32 EPT_AH_SendTrigger(byte trigger_value);
    [DllImport(activehost_dll)]
    static extern unsafe Int32 EPT_AH_SendByte(Int32 device_channel, char data_byte);
    [DllImport(activehost_dll)]
    static extern unsafe Int32 EPT_AH_SendBlock(Int32 device_channel, void* data, UInt32 data_size);
    [DllImport(activehost_dll)]
    static extern unsafe Int32 EPT_AH_SendTransferControlByte(char address_to_device, char payload);
    [DllImport(activehost_dll)]
    static extern unsafe Int32 EPT_AH_RegisterReadCallback(IntPtr read_callback);
    [DllImport(activehost_dll)]
    static extern unsafe char* EPT_AH_GetLastError();
    [DllImport(activehost_dll)]
    static extern unsafe Int32 EPT_AH_PerformSelfTest();
    [DllImport(activehost_dll)]
    static extern unsafe Int32 EPT_AH_LEDBlinky(Int32 milliseconds, Int32 count, byte* sequence, Int32 sequence_size);
    [DllImport(activehost_dll)]
    static extern unsafe Int32 EPT_AH_SetDebugMode(Int32 debug_mode);
    [DllImport(activehost_dll)]
    static extern unsafe Int32 EPT_AH_RegisterReadCallbackForChannel(IntPtr* read_callback, Int32 channel_index);
    [DllImport(activehost_dll)]
    static extern unsafe int EPT_AH_FlushDeviceChannelBuffer(Int32 device_index, Int32 channel_index);
    [DllImport(activehost_dll)]
    static extern unsafe UInt32 EPT_AH_GetDeviceChannelFreeBufferBytes(Int32 device_index, Int32 channel_index);
    [DllImport(activehost_dll)]
    static extern unsafe UInt32 EPT_AH_GetDeviceChannelPendingBufferBytes(Int32 device_index, Int32 channel_index);
    [DllImport(activehost_dll)]
    static extern unsafe bool EPT_AH_SetChannelConnectionFlag(Int32 device_index, Int32 channel_index, UInt32 flag, bool value);
    [DllImport(activehost_dll)]
    static extern unsafe bool EPT_AH_GetChannelConnectionFlag(Int32 device_index, Int32 channel_index, UInt32 flag);

    [UnmanagedFunctionPointer(CallingConvention.Cdecl)]
    unsafe delegate void MyEPTReadFunction(Int32 device_id, Int32 device_channel, byte command, byte payload, byte* data, byte data_size);
    MyEPTReadFunction MyEPTReadFunctionPTR;

    // Main connection function
    public static unsafe Int32 UpdateDeviceList()
    {

        // Open and check the DLL
        if (EPT_AH_Open(null, null, null) != 0)
        {
            Console.WriteLine("Could not attach to the ActiveHost library");
            return -1;
        }

        // Query connected devices
        Console.WriteLine("List of connected ActiveHost devices");
        num_devices = EPT_AH_QueryDevices();

        // Generate device list
        device_list = new string[num_devices];
        for (int i = 0; i < num_devices; i++)
        {
            String device_name;
            device_name = Marshal.PtrToStringAnsi((IntPtr)EPT_AH_GetDeviceName(i));
            device_list[i] = device_name;
        }
        return 0;
    }

    // Open the specified device
    public static unsafe Int32 OpenDevice(int device_id)
    {
        if (device_id >= num_devices)
        {
            Console.WriteLine("Error: Device {0} does not exist", device_id);
            return -1;
        }

        if (EPT_AH_OpenDeviceByIndex(device_id) == 0)
        {
            Console.WriteLine("Error opening device: " + Marshal.PtrToStringAnsi((IntPtr)EPT_AH_GetDeviceName(device_id))
                                                       + ", "
                                                       + Marshal.PtrToStringAnsi((IntPtr)EPT_AH_GetDeviceSerial(device_id)));
            return -1;
        }

        // Make the opened device the active device
        if (EPT_AH_SelectActiveDeviceByIndex(device_id) == 0)
        {
            Console.WriteLine("Error selecting device: %s " + Marshal.PtrToStringAnsi((IntPtr)EPT_AH_GetLastError()));
            return -1;
        }

        // Register the read callback function
        RegisterCallBack();
        //SetButtonEnables();

        // Set channel 0 to be dropped when data is overflowed
        //EPT_AH_SetChannelConnectionFlag(device_index, 0, AH_CS_UNRELIABLE_DROP, true);
        // Set channel 1 to completely flush the buffer when data is overflowed
        //EPT_AH_SetChannelConnectionFlag(device_index, 0, AH_CS_UNRELIABLE_FLUSH, true);

        Console.WriteLine("Successfully opened device: " + Marshal.PtrToStringAnsi((IntPtr)EPT_AH_GetDeviceName(device_id)));

        return 0;
    }

    private const byte TRIGGER_OUT_COMMAND = 0x1;
    private const byte BYTE_OUT_COMMAND = 0x2;
    private const byte BLOCK_OUT_COMMAND = 0x4;
    private const byte COMMAND_DECODE = 0x38;
    unsafe static void CallbackFunction(Int32 device_id, Int32 device_channel, byte command, byte payload, byte* data, byte data_size)
    {
        watch.Stop();
        Console.WriteLine("Received data from FPGA:");
        Console.WriteLine("Device ID: {0}", device_id);
        Console.WriteLine("Device Channel: {0}", device_channel);
        Console.WriteLine("Data Size: {0}", data_size);

        int decoded_command = (command & COMMAND_DECODE) >> 3;
        switch (decoded_command)
        {
            case TRIGGER_OUT_COMMAND:
                Console.WriteLine("Command: Trigger");
                break;
            case BYTE_OUT_COMMAND:
                Console.WriteLine("Command: Byte");
                break;
            case BLOCK_OUT_COMMAND:
                Console.WriteLine("Command: Block");
                break;
            default:
                Console.WriteLine("Error: Bad Command");
                break;
        }
        Console.WriteLine("Data:");
        for (int i = 0; i < data_size/4; i++)
        {
            Console.WriteLine("{0,5}", ((uint*)data)[i]);
        }
        Console.WriteLine("Payload: {0}", Convert.ToString(payload, 2).PadLeft(8, '0'));
        Console.WriteLine("Multiplication Time: {0} us", (double)watch.ElapsedTicks/Stopwatch.Frequency*1000000);

    }

    unsafe static Int32 RegisterCallBack()
    {
        // Get function pointer from C# function
        CallbackPrototypePtr = new CallbackPrototype(CallbackFunction);
        IntPtr callback_function_pointer = Marshal.GetFunctionPointerForDelegate(CallbackPrototypePtr);

        if (EPT_AH_RegisterReadCallback(callback_function_pointer) == 0)
        {
            Console.WriteLine("Error registering callback function: " + Marshal.PtrToStringAnsi((IntPtr)EPT_AH_GetLastError()));
            return -1;
        }

        return 0;
    }

    public static unsafe void BlockArrayWrite(int address, uint* data, uint length)
    {
        // Send data in chunks of TRANSFER_MAX_INTS ints (128 bytes)
        while (length > TRANSFER_MAX_INTS)
        {
            EPT_AH_SendBlock(address, (void*)data, (TRANSFER_MAX_INTS * sizeof(uint)));
            data += TRANSFER_MAX_INTS;
            length -= TRANSFER_MAX_INTS;
        }

        // Send remainder
        if (length > 0)
        {
            EPT_AH_SendBlock(address, (void*)data, (length * sizeof(uint)));
        }    
    }

    public static unsafe void SlowArrayWrite(int channel, byte[] data, int length)
    {
        for (int i = 0; i < length; i++)
        {
            Thread.Sleep(100);
            EPT_AH_SendByte(channel, (char)data[i]);
        }
    }

    public static unsafe void SendReset()
    {
        byte RESET_TRIGGER = 128;
        EPT_AH_SendTrigger(RESET_TRIGGER);
    }

    public static unsafe void SendRowDoneTrigger()
    {
        byte ROW_DONE = 1;
        EPT_AH_SendTrigger(ROW_DONE);
    }
}

