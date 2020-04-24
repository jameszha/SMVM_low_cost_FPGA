using Microsoft.VisualBasic.FileIO;
using System;
using System.Reflection;
using System.Runtime.InteropServices;
using System.Threading;

namespace matrix_matrix_multiply
{
    class Program
    {
        static unsafe void Main(string[] args)
        {
            Console.WriteLine("Hello World!");
            var matrix_A_path = args[0];
            var matrix_B_path = args[1];
            var output_path = args[2];

            var n = 6;
            var matrix_A = new Matrix(n, n);
            var matrix_B = new Matrix(n, n);

            // Load matrix A
            using (TextFieldParser csv_parser = new TextFieldParser(matrix_A_path))
            {
                csv_parser.CommentTokens = new string[] { "#" };
                csv_parser.SetDelimiters(new string[] { "," });

                for(int i = 0; i < n; i++)
                {
                    string[] row_data = csv_parser.ReadFields();
                    for (int j = 0; j < n; j++)
                    {
                        matrix_A[i,j] = Convert.ToInt32(row_data[j]);
                    }
                    
                }
            }

            // Load matrix B
            using (TextFieldParser csv_parser = new TextFieldParser(matrix_B_path))
            {
                csv_parser.CommentTokens = new string[] { "#" };
                csv_parser.SetDelimiters(new string[] { "," });

                for (int i = 0; i < n; i++)
                {
                    string[] row_data = csv_parser.ReadFields();
                    for (int j = 0; j < n; j++)
                    {
                        matrix_B[i, j] = Convert.ToInt32(row_data[j]);
                    }

                }
            }

            Console.WriteLine(matrix_A);
            Console.WriteLine(matrix_B);
            // Reference Solution
            var output_matrix = matrix_A * matrix_B;
            Console.WriteLine(output_matrix);

            FPGA.UpdateDeviceList();
            FPGA.OpenDevice(0);

            var temp_buf = new byte[36];
            for (int i = 0; i < 36; i++)
            {
                temp_buf[i] = Convert.ToByte(i);
            }
            FPGA.SlowArrayWrite(2, temp_buf, 36);
            while (true)
            {
                
            }
            
            /*
            fixed (byte* buf = temp_buf) 
            {
                while (true)
                {
                    FPGA.BlockImageWrite(2, buf, 36);
                    Thread.Sleep(1);
                }
                
            }*/

            while (true) ;

        }
    }
}
