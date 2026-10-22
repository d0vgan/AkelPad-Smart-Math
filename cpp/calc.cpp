#include "MathParser.hpp"

#include <cctype>
#include <iostream>
#include <string>

#if defined(_WIN32)
#include <io.h>
#include <stdio.h>
#endif

namespace {

const bool kEnableTimeValues = true;
const bool kEnableComplexNumbers = true;
const bool kEnableLambdaFunctions = true;
const bool kShowErrors = true;

std::string trimCopy(const std::string& text) {
  std::size_t begin = 0;
  while (begin < text.size() && std::isspace(static_cast<unsigned char>(text[begin])) != 0) {
    ++begin;
  }
  std::size_t end = text.size();
  while (end > begin && std::isspace(static_cast<unsigned char>(text[end - 1])) != 0) {
    --end;
  }
  return text.substr(begin, end - begin);
}

std::string lowerAscii(std::string text) {
  for (std::size_t i = 0; i < text.size(); ++i) {
    text[i] = static_cast<char>(std::tolower(static_cast<unsigned char>(text[i])));
  }
  return text;
}

bool isQuitCommand(const std::string& line) {
  const std::string lowered = lowerAscii(line);
  return lowered == "quit" || lowered == "exit";
}

bool stdinIsConsole() {
#if defined(_WIN32)
  return _isatty(_fileno(stdin)) != 0;
#else
  return false;
#endif
}

void applyDefaultFeatures(MathParser& parser) {
  parser.setSupportTimeValues(kEnableTimeValues);
  parser.setSupportComplexNumbers(kEnableComplexNumbers);
  parser.setSupportLambdaFunctions(kEnableLambdaFunctions);
}

int evaluateAndPrint(MathParser& parser, const std::string& expression) {
  parser.parseAndEvaluate(expression);
  const std::string error = parser.getError();
  if (!error.empty()) {
    if (kShowErrors) {
      std::cout << error << '\n';
    }
    return 1;
  }
  std::cout << parser.getResult() << '\n';
  return 0;
}

}  // namespace

int main(int argc, char** argv) {
  MathParser parser;
  applyDefaultFeatures(parser);

  if (argc > 1) {
    std::string expression;
    for (int i = 1; i < argc; ++i) {
      if (i > 1) {
        expression.push_back(' ');
      }
      expression += argv[i];
    }
    return evaluateAndPrint(parser, expression);
  }

  const bool interactive = stdinIsConsole();
  if (interactive) {
    std::cout << "Time values, complex numbers, and lambdas are on." << std::endl
              << "Waiting for a math expression or 'quit'/'exit'." << std::endl;
  }

  int status = 0;
  std::string line;
  while (true) {
    if (interactive) {
      std::cout << "> " << std::flush;
    }
    if (!std::getline(std::cin, line)) {
      break;
    }
    const std::string trimmed = trimCopy(line);
    if (trimmed.empty()) {
      continue;
    }
    if (isQuitCommand(trimmed)) {
      break;
    }
    if (evaluateAndPrint(parser, trimmed) != 0) {
      status = 1;
    }
  }
  return interactive ? 0 : status;
}
