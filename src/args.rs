//! Parses command line arguments
//!
//! # Args
//!
//! Parses the command line arguments
//!

use clap::Parser;
use std::env;

#[derive(Parser, Debug)]
#[clap(author, version, about, long_about = None)]
pub struct Args {
    /// Read from a file instead of stdin
    #[clap(short, long)]
    pub infile: Option<String>,

    /// Write to a file instead of stdout
    #[clap(short, long)]
    pub outfile: Option<String>,

    /// Display no output
    #[clap(short, long)]
    pub silent: bool,
}

/// Implementations for Args
impl Args {
    /// Parses the command line arguments
    pub fn parse() -> Self {
        let args = Args::try_parse().unwrap_or_else(|e| e.exit());

        let infile = args.infile;

        let outfile = args.outfile;

        // If the environment variable PV_SILENT has been set, no matter its content, set silent to true
        let silent = args.silent || !env::var("PV_SILENT").unwrap_or_default().is_empty();

        Self {
            infile,
            outfile,
            silent,
        }
    }
}
