#![cfg(unix)]
#![allow(unused_variables)]
use std::fs::File;
use std::io::{self, Write};
use std::fs::OpenOptions;
use std::str;
use custom_mutator::{export_mutator, CustomMutator};
//use std::io::Error;
use std::error::Error;
use rand::{Rng, thread_rng}; // Import ThreadRng
use rand::rngs::ThreadRng;
use std::process;

use std::cmp;
use std::time::{Instant, Duration};

use std::env;
use lrlex::lrlex_mod;
use lrpar::lrpar_mod;

use lrlex::LRNonStreamingLexerDef;

lrlex_mod!("lua.l");
lrpar_mod!("lua.y");

struct RepairMutation {
    own_buffer: Vec<u8>,
    lexerdef: LRNonStreamingLexerDef<lrlex::defaults::DefaultLexerTypes>,
    rng: ThreadRng,
    probability: f64,
    total_executions: u32,
    invalid_inputs: u32,
    successful_repairs: u32,
    failed_repairs: u32,
    start_time: Instant,
    execution_hours: u64,
    repair_duration: u128,
    output_filename: String,
}

impl CustomMutator for RepairMutation {
    type Error = ();
    //type Error = io::Error;

    fn init(seed: u32) -> Result<Self, Self::Error> {
        Ok(Self {
            own_buffer: Vec::new(),
            lexerdef: lua_l::lexerdef(),
            rng: thread_rng(),
            probability: std::env::var("REPAIR_PROBABILITY").ok().and_then(|v| v.parse::<f64>().ok()).unwrap_or(0.95),
            total_executions: 0,
            invalid_inputs: 0,
            successful_repairs: 0,
            failed_repairs: 0,
            start_time: Instant::now(),
            execution_hours: 0,
            repair_duration: 0,
            output_filename: std::env::var("FILENAME_REPAIR_STATS").unwrap_or_else(|_| "/home/benchmarks/results/stats/hello.log".to_string()),
        })
    }

    fn fuzz<'b, 's: 'b>(
        &'s mut self,
        buffer: &'b mut [u8],
        add_buff: Option<&[u8]>,
        max_size: usize,
    ) -> Result<Option<&'b [u8]>, Self::Error> {
        return Ok(Some(buffer));
        let mut rng = rand::thread_rng();
    
        // Randomly choose between the two mutations.
        let mutation_choice = rng.gen_bool(0.5); // true = first mutation, false = second mutation
    
        if mutation_choice {
            // First Mutation: Randomly select a portion of the `buffer` and insert it into `add_buff`.
            let buffer_len = buffer.len();
            let start_idx = rng.gen_range(0..buffer_len);
            let end_idx = rng.gen_range(start_idx..buffer_len);
            let portion = &buffer[start_idx..end_idx];
    
            // Handle the case where `add_buff` is None.
            let mut new_buff = match add_buff {
                Some(add_buff) => add_buff.to_vec(),
                None => Vec::new(),
            };
    
            // Determine the maximum index we can insert the portion.
            let max_insert_index = cmp::min(new_buff.len(), max_size - portion.len());
            let insert_idx = if max_insert_index > 0 {
                rng.gen_range(0..=max_insert_index)
            } else {
                0
            };
    
            // Insert the portion into the new buffer.
            new_buff.splice(insert_idx..insert_idx, portion.iter().cloned());
    
            // Ensure the new buffer does not exceed `max_size`.
            if new_buff.len() > max_size {
                new_buff.truncate(max_size);
            }
    
            // Leak the new buffer and return a reference to it.
            let leaked_buff: &'b [u8] = &*Box::leak(new_buff.into_boxed_slice());
            return Ok(Some(leaked_buff));
        } else {
            // Second Mutation: Find a "var_" word and duplicate it ahead in the buffer.
    
            // Convert buffer to string for easier manipulation.
            let buffer_str = String::from_utf8_lossy(buffer);
            let mut new_buff = buffer_str.to_string();
    
            // Find the first occurrence of a word starting with "var_".
            if let Some(var_pos) = new_buff.find("var_") {
                // Find the end of the word starting with "var_".
                let word_end = new_buff[var_pos..]
                    .find(|c: char| !c.is_alphanumeric() && c != '_')
                    .map_or(new_buff.len(), |offset| var_pos + offset);
                
                // Take a copy of the word to avoid immutable borrow.
                let var_word = new_buff[var_pos..word_end].to_string();
    
                // Find a valid position 10 to 100 bytes ahead to insert the word.
                let insert_start = cmp::min(word_end + 10, new_buff.len());
                let insert_end = cmp::min(word_end + 100, new_buff.len());
    
                // Find a space or newline between `insert_start` and `insert_end` to insert the word.
                let insert_idx = (insert_start..insert_end)
                    .find(|&idx| new_buff.as_bytes()[idx].is_ascii_whitespace())
                    .unwrap_or(insert_end);
    
                // Insert the duplicated word at the found index.
                new_buff.insert_str(insert_idx, &var_word);
    
                // Ensure the new buffer does not exceed `max_size`.
                if new_buff.len() > max_size {
                    new_buff.truncate(max_size);
                }
    
                // Leak the new buffer and return a reference to it.
                let final_buff: &'b [u8] = &*Box::leak(new_buff.into_bytes().into_boxed_slice());
                return Ok(Some(final_buff));
            } else {
                // If no "var_" word is found, return the original buffer.
                return Ok(Some(buffer));
            }
        }
    }
    

    fn post_process<'b, 's: 'b>(
        &'s mut self,
        buffer: &'b mut [u8],
    ) -> Result<Option<&'b [u8]>, Self::Error> {
        self.total_executions += 1;
        let dice: f64 = self.rng.gen();
        let elapsed = self.start_time.elapsed().as_secs();

        let hours_elapsed = elapsed / 3600;

        if hours_elapsed > self.execution_hours {
            self.execution_hours = hours_elapsed;
            write_success_ratio(&self.output_filename, self.execution_hours, self.total_executions, self.invalid_inputs, self.repair_duration, self.successful_repairs).unwrap_or_else(|err| eprintln!("Error: {}", err));
        }

        if dice > self.probability {
            // Return early: no repairs
            return Ok(Some(buffer));
        }

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
        let repair_start_time = Instant::now();
        let (res, errs) = lua_y::parse(&lexer);

        if errs.is_empty() {
            return Ok(Some(buffer));
        }

        let elapsed_rt = repair_start_time.elapsed().as_millis();
        self.repair_duration += elapsed_rt;

        self.invalid_inputs += 1;
        // Check and get result
        match res {
            Some(Ok(r)) => {
                let var = String::from(r);
                output_string = var;
                self.successful_repairs += 1;
            },
            _ => {
                // Unable to repair before timeout
                output_string = String::from("Unable to evaluate expression.");
                self.failed_repairs += 1;
                return Err(())
            }
        }

        let string_length = output_string.len();
        self.own_buffer = vec![0u8; string_length];
        self.own_buffer.copy_from_slice(output_string.as_bytes());
        let out = self.own_buffer.as_slice();

        Ok(Some(out))
    }

}

fn write_success_ratio(output_filename: &str, execution_hours: u64, total_executions: u32, invalid_inputs: u32, repair_duration: u128, successful_repairs: u32) -> io::Result<()> {
    // Calculate success ratio
    let success_ratio = if invalid_inputs > 0 {
        successful_repairs as f64 / invalid_inputs as f64
    } else {
        0.0
    };

    let mut info_string = String::new();

    info_string.push_str(&format!("\n--- Custom Mutation Stats : LUA : {} h ---\n", execution_hours));
    info_string.push_str(&format!("Total executions:   {}\n", total_executions));
    info_string.push_str(&format!("Invalid inputs:     {}\n", invalid_inputs));
    info_string.push_str(&format!("Total repair time:  {} s\n", repair_duration / 1000));
    info_string.push_str(&format!("Successful repairs: {}\n", successful_repairs));
    info_string.push_str(&format!("Success ratio:      {:.2} %\n", success_ratio * 100.0));
    info_string.push_str("\n");

    let mut output_file = OpenOptions::new()
        .create(true)
        .append(true)
        .open(output_filename)?;

    // Write the success ratio to the file
    output_file.write_all(info_string.as_bytes())?;
    
    Ok(())
}

export_mutator!(RepairMutation);
