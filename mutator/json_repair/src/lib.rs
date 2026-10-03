#![cfg(unix)]
#![allow(unused_variables)]
use std::fs::File;
use std::io::{self, Write};
use std::str;
use custom_mutator::{export_mutator, CustomMutator};
//use std::io::Error;
use std::error::Error;
use rand::{Rng, thread_rng}; // Import ThreadRng
use rand::rngs::ThreadRng;
//use rand::Rng;


use std::env;
use lrlex::lrlex_mod;
use lrpar::lrpar_mod;

use lrlex::LRNonStreamingLexerDef;

lrlex_mod!("json.l");
lrpar_mod!("json.y");

struct RepairMutation {
    own_buffer: Vec<u8>,
    lexerdef: LRNonStreamingLexerDef<lrlex::defaults::DefaultLexerTypes>,
    rng: ThreadRng,
    probability: f64,
    total_executions: u32,
    failed_executions: u32,

}

impl CustomMutator for RepairMutation {
    type Error = ();
    //type Error = io::Error;

    fn init(seed: u32) -> Result<Self, Self::Error> {
        Ok(Self {
            own_buffer: Vec::new(),
            lexerdef: json_l::lexerdef(),
            rng: thread_rng(),
            probability: 1.0,
            total_executions: 0,
            failed_executions: 0,
        })
    }

    fn fuzz<'b, 's: 'b>(
        &'s mut self,
        buffer: &'b mut [u8],
        add_buff: Option<&[u8]>,
        max_size: usize,
    ) -> Result<Option<&'b [u8]>, Self::Error> {
        return Ok(Some(buffer));
    }

    fn post_process<'b, 's: 'b>(
        &'s mut self,
        buffer: &'b mut [u8],
    ) -> Result<Option<&'b [u8]>, Self::Error> {
        
        let dice: f64 = self.rng.gen();

        //if dice > self.probability {
            // Return early: no repairs
        //    return Ok(Some(buffer));
        //}

        self.total_executions += 1;
        let mut output_string = String::from("abc");

        // convert buffer into String
        let input_string = if let Ok(string) = String::from_utf8(buffer.to_vec()) {
            string
        } else {
            // Not a valid UTF-8 sequence!
            String::from_utf8_lossy(buffer).to_string()
        };

        // lex and parse the input
        let lexer = self.lexerdef.lexer(&input_string);
        let (res, errs) = json_y::parse(&lexer);

        // Check and get result
        match res {
            Some(Ok(r)) => {
                let var = String::from(r);
                output_string = var;
            },
            _ => {
                // Unable to repair before timeout
                output_string = String::from("Unable to evaluate expression.");
                //write_to_file(input_string, output_string).unwrap_or_else(|err| eprintln!("Error: {}", err));
                self.failed_executions += 1;
                //return Ok(Some(buffer));
                return Err(())
            }
            //output_string = input_string
            //eprintln!("Unable to evaluate expression.")
        }


        //if self.total_executions % 100 == 0 {
        //    write_stats(self.total_executions, self.failed_executions);
        //}
        let string_length = output_string.len();
        self.own_buffer = vec![0u8; string_length];
        self.own_buffer.copy_from_slice(output_string.as_bytes());
        let out = self.own_buffer.as_slice();
        //write_to_file(input_string, output_string).unwrap_or_else(|err| eprintln!("Error: {}", err));
        
        if dice > self.probability {
            // Return early: no repairs
            return Ok(Some(buffer));
        } else {
            Ok(Some(out))
        }
        
        //Ok(Some(out))
    }
}

fn write_to_file(input_string: String, output_string: String) -> io::Result<()> {
    // Combine the two strings
    let combined_string = format!("\n{}\n\n{}\n\n", input_string, output_string);
    // Open the file
    let mut output_file = File::create("output_repair.txt")?;
    // Write the combined string to the file
    output_file.write_all(combined_string.as_bytes())?;
    Ok(())
}

fn write_stats(total_executions: u32, failed_executions: u32) -> io::Result<()> {
    // Combine the two strings
    let combined_string = format!("\nTotal executions: {}\n\nFailed executions: {}\n\n", total_executions.to_string(), failed_executions.to_string());
    // Open the file
    let mut output_file = File::create("output_repair_stats.txt")?;
    // Write the combined string to the file
    output_file.write_all(combined_string.as_bytes())?;
    Ok(())
}

export_mutator!(RepairMutation);
