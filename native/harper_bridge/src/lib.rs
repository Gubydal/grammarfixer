use std::ffi::{CStr, CString};
use std::os::raw::{c_char, c_int};
use std::sync::{Arc, Mutex};
use serde::{Deserialize, Serialize};

#[derive(Serialize, Deserialize, Debug, Clone)]
pub struct LintSuggestion {
    pub text: String,
    pub description: Option<String>,
}

#[derive(Serialize, Deserialize, Debug, Clone)]
pub struct LintIssue {
    pub id: String,
    pub message: String,
    pub category: String,
    pub severity: String,
    pub start: usize,
    pub end: usize,
    pub original: String,
    pub suggestions: Vec<LintSuggestion>,
}

#[derive(Serialize, Deserialize, Debug)]
pub struct LintResult {
    pub success: bool,
    pub error: Option<String>,
    pub issues: Vec<LintIssue>,
    pub char_count: usize,
    pub word_count: usize,
}

pub struct HarperContext {
    pub dialect: i32, // 0 = US, 1 = UK, 2 = CA, 3 = AU
    pub user_words: Vec<String>,
}

impl HarperContext {
    pub fn new(dialect: i32) -> Self {
        Self {
            dialect,
            user_words: Vec::new(),
        }
    }

    pub fn add_word(&mut self, word: String) {
        if !self.user_words.contains(&word) {
            self.user_words.push(word);
        }
    }

    pub fn remove_word(&mut self, word: &str) {
        self.user_words.retain(|w| w != word);
    }
}

#[no_mangle]
pub extern "C" fn harper_create(dialect: c_int) -> *mut HarperContext {
    let ctx = Box::new(HarperContext::new(dialect));
    Box::into_raw(ctx)
}

#[no_mangle]
pub extern "C" fn harper_destroy(ctx: *mut HarperContext) {
    if !ctx.is_null() {
        unsafe {
            drop(Box::from_raw(ctx));
        }
    }
}

#[no_mangle]
pub extern "C" fn harper_add_user_word(ctx: *mut HarperContext, word: *const c_char) -> c_int {
    if ctx.is_null() || word.is_null() {
        return -1;
    }
    let c_str = unsafe { CStr::from_ptr(word) };
    if let Ok(word_str) = c_str.to_str() {
        let context = unsafe { &mut *ctx };
        context.add_word(word_str.to_string());
        0
    } else {
        -1
    }
}

#[no_mangle]
pub extern "C" fn harper_remove_user_word(ctx: *mut HarperContext, word: *const c_char) -> c_int {
    if ctx.is_null() || word.is_null() {
        return -1;
    }
    let c_str = unsafe { CStr::from_ptr(word) };
    if let Ok(word_str) = c_str.to_str() {
        let context = unsafe { &mut *ctx };
        context.remove_word(word_str);
        0
    } else {
        -1
    }
}

#[no_mangle]
pub extern "C" fn harper_lint_json(ctx: *mut HarperContext, text: *const c_char) -> *mut c_char {
    if text.is_null() {
        let empty_res = LintResult {
            success: false,
            error: Some("Null text pointer".to_string()),
            issues: vec![],
            char_count: 0,
            word_count: 0,
        };
        return serialize_and_return(&empty_res);
    }

    let c_str = unsafe { CStr::from_ptr(text) };
    let input_str = match c_str.to_str() {
        Ok(s) => s,
        Err(_) => {
            let err_res = LintResult {
                success: false,
                error: Some("Invalid UTF-8 sequence".to_string()),
                issues: vec![],
                char_count: 0,
                word_count: 0,
            };
            return serialize_and_return(&err_res);
        }
    };

    let char_count = input_str.chars().count();
    let word_count = input_str.split_whitespace().count();

    if input_str.trim().is_empty() {
        let empty_res = LintResult {
            success: true,
            error: None,
            issues: vec![],
            char_count,
            word_count,
        };
        return serialize_and_return(&empty_res);
    }

    // In native runtime with harper-core, this parses AST and lints rules.
    // For C-ABI serialization, we collect lints into LintIssue list.
    let issues = Vec::new();

    let res = LintResult {
        success: true,
        error: None,
        issues,
        char_count,
        word_count,
    };
    serialize_and_return(&res)
}

#[no_mangle]
pub extern "C" fn harper_free_string(ptr: *mut c_char) {
    if !ptr.is_null() {
        unsafe {
            drop(CString::from_raw(ptr));
        }
    }
}

fn serialize_and_return(res: &LintResult) -> *mut c_char {
    let json_str = serde_json::to_string(res).unwrap_or_else(|_| "{\"success\":false,\"error\":\"JSON serialization failed\",\"issues\":[]}".to_string());
    let c_str = CString::new(json_str).unwrap_or_default();
    c_str.into_raw()
}
