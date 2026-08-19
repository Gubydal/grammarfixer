#ifndef HARPER_BRIDGE_H
#define HARPER_BRIDGE_H

#ifdef __cplusplus
extern "C" {
#endif

#include <stddef.h>
#include <stdint.h>

typedef struct HarperContext HarperContext;

/**
 * Creates a new Harper grammar checking context for the specified dialect.
 * dialect: 0 = American, 1 = British, 2 = Canadian, 3 = Australian.
 */
HarperContext* harper_create(int32_t dialect);

/**
 * Destroys a Harper context and releases all allocated memory.
 */
void harper_destroy(HarperContext* ctx);

/**
 * Adds a word to the user dictionary so it is not flagged as a spelling error.
 */
int32_t harper_add_user_word(HarperContext* ctx, const char* word);

/**
 * Removes a word from the user dictionary.
 */
int32_t harper_remove_user_word(HarperContext* ctx, const char* word);

/**
 * Lints the provided UTF-8 text and returns a heap-allocated JSON string containing lint issues.
 * The caller must free the returned pointer using harper_free_string().
 */
char* harper_lint_json(HarperContext* ctx, const char* text);

/**
 * Frees a string returned by harper_lint_json().
 */
void harper_free_string(char* ptr);

#ifdef __cplusplus
}
#endif

#endif /* HARPER_BRIDGE_H */
