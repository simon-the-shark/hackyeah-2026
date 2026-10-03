// Runs the converted concern classifier through the MindSpore Lite runtime on the export's check prompts,
// to confirm conversion/quantization keeps the yes/no scores and to measure latency per check.
// Input (stdin): one line per prompt: "<expectedScore> <id> <id> ...". Usage: check_classifier model.ms maxTokens padId
#include <chrono>
#include <cmath>
#include <cstdlib>
#include <iostream>
#include <sstream>
#include <string>
#include <vector>

#include "include/api/context.h"
#include "include/api/model.h"
#include "include/api/types.h"

int main(int argc, char **argv) {
  if (argc < 4) {
    std::cerr << "usage: check_classifier model.ms maxTokens padId < prompts.txt\n";
    return 2;
  }
  const int maxTokens = std::stoi(argv[2]), padId = std::stoi(argv[3]);
  auto context = std::make_shared<mindspore::Context>();
  context->SetThreadNum(4);
  auto cpu = std::make_shared<mindspore::CPUDeviceInfo>();
  const char *fp16 = std::getenv("MS_FP16");
  cpu->SetEnableFP16(fp16 != nullptr && std::string(fp16) == "1");
  context->MutableDeviceInfo().push_back(cpu);
  mindspore::Model model;
  auto loadStart = std::chrono::steady_clock::now();
  if (model.Build(argv[1], mindspore::kMindIR_Lite, context) != mindspore::kSuccess) {
    std::cerr << "build failed\n";
    return 1;
  }
  std::cout << "load_ms " << std::chrono::duration<double, std::milli>(std::chrono::steady_clock::now() - loadStart).count()
            << "\n";
  auto inputs = model.GetInputs();
  mindspore::MSTensor *tokens = nullptr, *length = nullptr;
  for (auto &t : inputs) {
    if (t.Name() == "tokens") tokens = &t;
    if (t.Name() == "length") length = &t;
  }
  if (tokens == nullptr || length == nullptr) {
    std::cerr << "missing inputs\n";
    return 1;
  }
  std::string line;
  double worst = 0, totalMs = 0;
  int count = 0, flipped = 0;
  while (std::getline(std::cin, line)) {
    std::istringstream in(line);
    double expected;
    in >> expected;
    std::vector<int32_t> ids;
    int id;
    while (in >> id) ids.push_back(id);
    auto *data = static_cast<int32_t *>(tokens->MutableData());
    for (int i = 0; i < maxTokens; i++) data[i] = i < static_cast<int>(ids.size()) ? ids[i] : padId;
    static_cast<int32_t *>(length->MutableData())[0] = static_cast<int32_t>(ids.size());
    std::vector<mindspore::MSTensor> outputs;
    auto start = std::chrono::steady_clock::now();
    if (model.Predict(inputs, &outputs) != mindspore::kSuccess) {
      std::cerr << "predict failed\n";
      return 1;
    }
    double ms = std::chrono::duration<double, std::milli>(std::chrono::steady_clock::now() - start).count();
    const float *scores = static_cast<const float *>(outputs[0].Data().get());
    double score = scores[0] - scores[1];
    worst = std::max(worst, std::abs(score - expected));
    if ((score > 0) != (expected > 0)) flipped++;
    totalMs += ms;
    count++;
    std::cout << "expected " << expected << " got " << score << " ms " << ms << "\n";
  }
  std::cout << "max_abs_diff " << worst << " flipped " << flipped << " avg_ms " << (count > 0 ? totalMs / count : 0)
            << "\n";
  // A quantized model may shift scores a little, but must not change any yes/no decision.
  return count > 0 && flipped == 0 && worst < 0.5 ? 0 : 1;
}
