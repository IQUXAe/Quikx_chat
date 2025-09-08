#include "utils.h"

#include <flutter_windows.h>
#include <io.h>
#include <stdio.h>
#include <windows.h>

#include <iostream>

void CreateAndAttachConsole() {
  if (::AllocConsole()) {
    FILE *console_file;
    if (!freopen_s(&console_file, "CONOUT$", "w", stdout)) {
      _dup2(_fileno(stdout), 1);
    }
    if (!freopen_s(&console_file, "CONOUT$", "w", stderr)) {
      _dup2(_fileno(stderr), 2);
    }
    std::ios::sync_with_stdio();
    FlutterDesktopResyncOutputStreams();
  }
}

std::vector<std::string> GetCommandLineArguments() {
  // Convert the UTF-16 command line arguments to UTF-8 for the Engine to use.
  int argc;
  wchar_t** argv = ::CommandLineToArgvW(::GetCommandLineW(), &argc);
  if (argv == nullptr) {
    return std::vector<std::string>();
  }

  std::vector<std::string> command_line_arguments;

  // Skip the first argument as it's the binary name.
  for (int i = 1; i < argc; i++) {
    std::string utf8_arg = Utf8FromUtf16(argv[i]);
    if (!utf8_arg.empty()) {
      command_line_arguments.push_back(utf8_arg);
    }
  }

  ::LocalFree(argv);

  return command_line_arguments;
}

std::string Utf8FromUtf16(const wchar_t* utf16_string) {
  if (utf16_string == nullptr) {
    return std::string();
  }
  
  // Get required buffer size
  int target_length = ::WideCharToMultiByte(
      CP_UTF8, WC_ERR_INVALID_CHARS, utf16_string,
      -1, nullptr, 0, nullptr, nullptr);
  
  if (target_length <= 0) {
    return std::string();
  }
  
  std::string utf8_string(target_length - 1, '\0'); // Exclude null terminator
  
  // Perform conversion
  int converted_length = ::WideCharToMultiByte(
      CP_UTF8, WC_ERR_INVALID_CHARS, utf16_string,
      -1, &utf8_string[0], target_length, nullptr, nullptr);
  
  if (converted_length <= 0) {
    return std::string();
  }
  
  return utf8_string;
}
