use crate::error::Error;
use serde::{Deserialize, Serialize};
use std::{fmt::Display, str::FromStr};

#[derive(Serialize, Deserialize, Debug)]
pub struct Net {
    identifier: String,
    #[serde(rename = "type")]
    dtype: String,
    mode: String,
    default: Option<String>,
}

impl Net {
    pub fn get_identifier(&self) -> &String {
        &self.identifier
    }

    pub fn get_type(&self) -> &String {
        &self.dtype
    }

    pub fn get_mode(&self) -> &String {
        &self.mode
    }

    pub fn get_default(&self) -> Option<&String> {
        self.default.as_ref()
    }

    pub fn set_default(&mut self, val: String) {
        self.default = Some(val);
    }

    pub fn is_input(&self) -> bool {
        self.mode.starts_with("in") == true && self.mode.contains("inout") == false
    }

    pub fn is_output(&self) -> bool {
        self.mode.starts_with("out") == true
    }

    /// Checks if this net has the same identifier
    pub fn is_identifier(&self, name: &str, ignore_case: bool) -> bool {
        match ignore_case {
            true => &self.identifier.to_uppercase() == &name.to_uppercase(),
            false => &self.identifier == &name,
        }
    }
}

#[derive(Serialize, Deserialize, Debug)]
pub struct Unit {
    identifier: String,
    generics: Vec<Net>,
    ports: Vec<Net>,
    architectures: Vec<String>,
    language: String,
}

impl Unit {
    pub fn get_ports(&self) -> &Vec<Net> {
        &self.ports
    }

    pub fn get_identifier(&self) -> &String {
        &self.identifier
    }

    pub fn get_generics(&self) -> &Vec<Net> {
        &self.generics
    }

    pub fn get_generics_mut(&mut self) -> &mut Vec<Net> {
        &mut self.generics
    }

    pub fn get_language(&self) -> &String {
        &self.language
    }
}

impl FromStr for Unit {
    type Err = Error;

    fn from_str(s: &str) -> Result<Self, Self::Err> {
        match serde_json::from_str(s) {
            Ok(r) => Ok(r),
            Err(e) => Err(Error::InvalidJson(Error::lowerize(e.to_string()))),
        }
    }
}

impl Display for Unit {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "{}", serde_json::to_string(self).unwrap())
    }
}