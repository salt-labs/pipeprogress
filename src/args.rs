//! Parses command line arguments
//!
//! # Args
//!
//! Parses the command line arguments
//!

use clap::{App, Arg};
use std::env;

/// Data structure to hold Args
pub struct Args {
    pub infile: String,
    pub outfile: String,
    pub silent: bool,
}

/// Implementations for Args
impl Args {
    /// Public function to parse the command line arguments
    pub fn parse() -> Self {
        let matches = App::new("pipeprogress")
            .arg(
                Arg::with_name("infile")
                    .short("i")
                    .long("infile")
                    .takes_value(true)
                    .help("Read from a file instead of stdin"),
            )
            .arg(
                Arg::with_name("outfile")
                    .short("o")
                    .long("outfile")
                    .takes_value(true)
                    .help("Writes to a file instead of stdout"),
            )
            .arg(
                Arg::with_name("silent")
                    .short("s")
                    .long("silent")
                    .takes_value(false)
                    .help("Display no output"),
            )
            .get_matches();

        let infile = matches.value_of("infile").unwrap_or_default().to_string();

        let outfile = matches.value_of("outfile").unwrap_or_default().to_string();

        let silent = if matches.is_present("silent") {
            true
        } else {
            // If the environment variable PV_SILENT has been set,
            // no matter whats contains, set to true
            !env::var("PV_SILENT").unwrap_or_default().is_empty()
        };

        Self {
            infile,
            outfile,
            silent,
        }
    }
}
