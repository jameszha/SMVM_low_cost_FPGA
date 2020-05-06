using Microsoft.VisualBasic.FileIO;
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Linq;
using System.IO;
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

            var dense_path = "matrix_data/wide.csv";
            var csr_path = "matrix_data/wide_csr.csv";
            var cisr_path = "matrix_data/wide_cisr.csv";

            StreamReader sr = new StreamReader(dense_path);
            var m =sr.ReadLine().Split(',').Length;

            var n = 6;
            var dense_matrix = new Matrix(n, m);

            // Load Dense Matrix Representation
            using (TextFieldParser csv_parser = new TextFieldParser(dense_path))
            {
                csv_parser.CommentTokens = new string[] { "#" };
                csv_parser.SetDelimiters(new string[] { "," });

                for(int i = 0; i < n; i++)
                {
                    string[] row_data = csv_parser.ReadFields();
                    for (int j = 0; j < m; j++)
                    {
                        dense_matrix[i,j] = Convert.ToInt32(row_data[j]);
                    }
                    
                }
            }

            // Load CISR Matrix Representation
            UInt32[] cisr_values;
            UInt32[] cisr_column_indices;
            UInt32[] cisr_row_lengths; 
            using (TextFieldParser csv_parser = new TextFieldParser(cisr_path))
            {
                csv_parser.CommentTokens = new string[] { "#" };
                csv_parser.SetDelimiters(new string[] { "," });

                string[] cisr_values_line = csv_parser.ReadFields();
                cisr_values = cisr_values_line.Select(UInt32.Parse).ToArray();

                string[] cisr_column_indices_line = csv_parser.ReadFields();
                cisr_column_indices = cisr_column_indices_line.Select(UInt32.Parse).ToArray();

                string[] cisr_row_lengths_line = csv_parser.ReadFields();
                cisr_row_lengths = cisr_row_lengths_line.Select(UInt32.Parse).ToArray();
            }


            // Display Loaded Matrix
            Console.WriteLine("Dense Matrix Representation:");
            Console.WriteLine(dense_matrix);
            Console.WriteLine("CISR Values:         " + String.Join(", ", cisr_values));
            Console.WriteLine("CISR Column Indices: " + String.Join(", ", cisr_column_indices));
            Console.WriteLine("CISR Row Lengths:    " + String.Join(", ", cisr_row_lengths));

            // Generate Reference Solution
            var vector = new Matrix(m, 1);
            for (int i = 0; i < m; i++)
            {
                vector[i, 0] = i;
            }
            var ref_watch = new System.Diagnostics.Stopwatch();
            ref_watch.Start();
            var result = dense_matrix * vector;
            ref_watch.Stop();
            Console.WriteLine("Result:");
            Console.WriteLine(result);
            Console.WriteLine("Multiplication Time: {0} us", (double)ref_watch.ElapsedTicks / Stopwatch.Frequency * 1000000);

            // Interleave Value and Column Indices into single array
            int num_nonzeros = cisr_values.Length;
            uint[] cisr_data = new uint[2 * num_nonzeros];
            for (int i = 0; i < num_nonzeros; i++)
            {
                cisr_data[2 * i] = cisr_values[i];
                cisr_data[2 * i + 1] = cisr_column_indices[i];
            }

            // Connect to FPGA
            FPGA.UpdateDeviceList();
            FPGA.OpenDevice(0);
            FPGA.SendReset();
            FPGA.watch.Start();

            // Transfer Row Lengths
            fixed (uint* data = cisr_row_lengths)
            {
                FPGA.BlockArrayWrite(1, data, (uint)cisr_row_lengths.Length);
            }
            FPGA.SendRowDoneTrigger();

            // Transfer Interleaved CISR Data
            fixed (uint* data = cisr_data)
            {   
                FPGA.BlockArrayWrite(2, data, (uint)cisr_data.Length);
            }
            while (true) ;
        }
    }
}


// Reference Solution
//var mmm_watch = new System.Diagnostics.Stopwatch();
//mmm_watch.Start();
//var output_matrix = matrix_A * matrix_B;
//var output_matrix = Matrix.StupidMultiply(matrix_A, matrix_B);
//mmm_watch.Stop();
//Console.WriteLine(output_matrix);
//Console.WriteLine("Matrix-Matrix Multiply Time: {0} us", (double)mmm_watch.ElapsedTicks / Stopwatch.Frequency * 1000000);
