#include "mcp_channel_plugin.h"

#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>
#include <windows.h>
#include <iostream>
#include <sstream>
#include <chrono>
// Simple JSON handling - in production use nlohmann/json or similar
// #include <nlohmann/json.hpp>

// Static registration method
void McpChannelPlugin::RegisterWithRegistrar(FlutterDesktopPluginRegistrarRef registrar) {
  // Minimal plugin registration - just register the plugin without channels for now
  // TODO: Implement MCP functionality in pure Dart instead
  
  // Keep a static instance alive to prevent deallocation
  static auto plugin = std::make_unique<McpChannelPlugin>();
  
  // Plugin registered successfully - MCP functionality will be handled in Dart
}

McpChannelPlugin::McpChannelPlugin() 
    : is_initialized_(false), node_process_(std::make_unique<NodeJsProcess>()) {
  // Get the MCP script path relative to the executable
  mcp_script_path_ = GetMcpScriptPath();
}

McpChannelPlugin::~McpChannelPlugin() {
  if (node_process_) {
    node_process_->Stop();
  }
}

void McpChannelPlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue>& method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  
  const std::string& method = method_call.method_name();
  const auto* arguments = std::get_if<flutter::EncodableMap>(method_call.arguments());

  if (!arguments) {
    result->Error("INVALID_ARGUMENTS", "Arguments must be a map");
    return;
  }

  if (method == "initialize") {
    InitializeMcp(*arguments, std::move(result));
  } else if (method == "processMessage") {
    ProcessMessage(*arguments, std::move(result));
  } else if (method == "streamMessage") {
    StreamMessage(*arguments, std::move(result));
  } else if (method == "testConnection") {
    TestConnection(*arguments, std::move(result));
  } else if (method == "getCapabilities") {
    GetCapabilities(*arguments, std::move(result));
  } else if (method == "injectContext") {
    InjectContext(*arguments, std::move(result));
  } else if (method == "dispose") {
    DisposeMcp(std::move(result));
  } else {
    result->NotImplemented();
  }
}

// Event Stream Handler Implementation
McpChannelPlugin::McpEventStreamHandler::McpEventStreamHandler(McpChannelPlugin* plugin)
    : plugin_(plugin) {}

McpChannelPlugin::McpEventStreamHandler::~McpEventStreamHandler() {}

std::unique_ptr<flutter::StreamHandlerError<flutter::EncodableValue>>
McpChannelPlugin::McpEventStreamHandler::OnListenInternal(
    const flutter::EncodableValue* arguments,
    std::unique_ptr<flutter::EventSink<flutter::EncodableValue>>&& events) {
  event_sink_ = std::move(events);
  return nullptr;
}

std::unique_ptr<flutter::StreamHandlerError<flutter::EncodableValue>>
McpChannelPlugin::McpEventStreamHandler::OnCancelInternal(
    const flutter::EncodableValue* arguments) {
  event_sink_.reset();
  return nullptr;
}

// Node.js Process Implementation
McpChannelPlugin::NodeJsProcess::NodeJsProcess() 
    : is_running_(false), child_stdin_write_(INVALID_HANDLE_VALUE),
      child_stdout_read_(INVALID_HANDLE_VALUE), child_stderr_read_(INVALID_HANDLE_VALUE) {
  ZeroMemory(&process_info_, sizeof(process_info_));
}

McpChannelPlugin::NodeJsProcess::~NodeJsProcess() {
  Stop();
}

bool McpChannelPlugin::NodeJsProcess::Start(const std::string& script_path) {
  if (is_running_) {
    return true;
  }

  // Create pipes for communication
  SECURITY_ATTRIBUTES security_attributes;
  security_attributes.nLength = sizeof(SECURITY_ATTRIBUTES);
  security_attributes.bInheritHandle = TRUE;
  security_attributes.lpSecurityDescriptor = NULL;

  HANDLE child_stdout_write, child_stdin_read, child_stderr_write;

  // Create pipes
  if (!CreatePipe(&child_stdout_read_, &child_stdout_write, &security_attributes, 0) ||
      !CreatePipe(&child_stdin_read, &child_stdin_write_, &security_attributes, 0) ||
      !CreatePipe(&child_stderr_read_, &child_stderr_write, &security_attributes, 0)) {
    return false;
  }

  // Ensure handles are not inherited
  SetHandleInformation(child_stdout_read_, HANDLE_FLAG_INHERIT, 0);
  SetHandleInformation(child_stdin_write_, HANDLE_FLAG_INHERIT, 0);
  SetHandleInformation(child_stderr_read_, HANDLE_FLAG_INHERIT, 0);

  // Create the Node.js process
  STARTUPINFOA startup_info;
  ZeroMemory(&startup_info, sizeof(startup_info));
  startup_info.cb = sizeof(startup_info);
  startup_info.hStdOutput = child_stdout_write;
  startup_info.hStdError = child_stderr_write;
  startup_info.hStdInput = child_stdin_read;
  startup_info.dwFlags |= STARTF_USESTDHANDLES;

  std::string command = "node \"" + script_path + "\"";

  if (!CreateProcessA(NULL, const_cast<char*>(command.c_str()), NULL, NULL, 
                     TRUE, CREATE_NO_WINDOW, NULL, NULL, &startup_info, &process_info_)) {
    CloseHandle(child_stdout_write);
    CloseHandle(child_stdin_read);
    CloseHandle(child_stderr_write);
    return false;
  }

  // Close handles not needed by parent
  CloseHandle(child_stdout_write);
  CloseHandle(child_stdin_read);
  CloseHandle(child_stderr_write);

  is_running_ = true;

  // Start reading threads
  output_thread_ = std::thread(&NodeJsProcess::ReadOutputThread, this);
  error_thread_ = std::thread(&NodeJsProcess::ReadErrorThread, this);

  return true;
}

void McpChannelPlugin::NodeJsProcess::Stop() {
  if (!is_running_) {
    return;
  }

  is_running_ = false;

  // Terminate the process
  if (process_info_.hProcess != INVALID_HANDLE_VALUE) {
    TerminateProcess(process_info_.hProcess, 0);
    CloseHandle(process_info_.hProcess);
    CloseHandle(process_info_.hThread);
  }

  // Close pipes
  if (child_stdin_write_ != INVALID_HANDLE_VALUE) {
    CloseHandle(child_stdin_write_);
    child_stdin_write_ = INVALID_HANDLE_VALUE;
  }
  if (child_stdout_read_ != INVALID_HANDLE_VALUE) {
    CloseHandle(child_stdout_read_);
    child_stdout_read_ = INVALID_HANDLE_VALUE;
  }
  if (child_stderr_read_ != INVALID_HANDLE_VALUE) {
    CloseHandle(child_stderr_read_);
    child_stderr_read_ = INVALID_HANDLE_VALUE;
  }

  // Wait for threads to finish
  if (output_thread_.joinable()) {
    output_thread_.join();
  }
  if (error_thread_.joinable()) {
    error_thread_.join();
  }
}

bool McpChannelPlugin::NodeJsProcess::IsRunning() const {
  return is_running_;
}

bool McpChannelPlugin::NodeJsProcess::SendMessage(const std::string& message) {
  if (!is_running_ || child_stdin_write_ == INVALID_HANDLE_VALUE) {
    return false;
  }

  std::string full_message = message + "\n";
  DWORD bytes_written;
  
  return WriteFile(child_stdin_write_, full_message.c_str(), 
                  static_cast<DWORD>(full_message.length()), &bytes_written, NULL);
}

void McpChannelPlugin::NodeJsProcess::SetMessageCallback(
    std::function<void(const std::string&)> callback) {
  std::lock_guard<std::mutex> lock(callback_mutex_);
  message_callback_ = callback;
}

void McpChannelPlugin::NodeJsProcess::ReadOutputThread() {
  char buffer[4096];
  DWORD bytes_read;
  std::string accumulated_data;

  while (is_running_ && child_stdout_read_ != INVALID_HANDLE_VALUE) {
    if (ReadFile(child_stdout_read_, buffer, sizeof(buffer) - 1, &bytes_read, NULL) && bytes_read > 0) {
      buffer[bytes_read] = '\0';
      accumulated_data += buffer;

      // Process complete JSON messages (one per line)
      size_t pos = 0;
      while ((pos = accumulated_data.find('\n')) != std::string::npos) {
        std::string message = accumulated_data.substr(0, pos);
        accumulated_data.erase(0, pos + 1);

        if (!message.empty()) {
          std::lock_guard<std::mutex> lock(callback_mutex_);
          if (message_callback_) {
            message_callback_(message);
          }
        }
      }
    } else {
      break;
    }
  }
}

void McpChannelPlugin::NodeJsProcess::ReadErrorThread() {
  char buffer[4096];
  DWORD bytes_read;

  while (is_running_ && child_stderr_read_ != INVALID_HANDLE_VALUE) {
    if (ReadFile(child_stderr_read_, buffer, sizeof(buffer) - 1, &bytes_read, NULL) && bytes_read > 0) {
      buffer[bytes_read] = '\0';
      std::cerr << "MCP Node.js Error: " << buffer << std::endl;
    } else {
      break;
    }
  }
}

// MCP Operations Implementation
void McpChannelPlugin::InitializeMcp(
    const flutter::EncodableMap& config,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  
  if (is_initialized_) {
    result->Success(flutter::EncodableValue(flutter::EncodableMap{
      {"success", flutter::EncodableValue(true)},
      {"message", flutter::EncodableValue("Already initialized")}
    }));
    return;
  }

  // Set up Node.js message callback
  node_process_->SetMessageCallback(
      [this](const std::string& message) {
        HandleNodeMessage(message);
      });

  // Start Node.js process
  if (!node_process_->Start(mcp_script_path_)) {
    result->Error("INITIALIZATION_FAILED", "Failed to start Node.js MCP process");
    return;
  }

  // Send initialization config to Node.js
  std::string request_id = "init_" + std::to_string(std::chrono::steady_clock::now().time_since_epoch().count());
  std::string config_json = EncodableValueToJsonString(flutter::EncodableValue(config));
  std::string init_message = "{\"method\":\"initialize\",\"params\":" + config_json + ",\"requestId\":\"" + request_id + "\"}";

  if (!node_process_->SendMessage(init_message)) {
    result->Error("INITIALIZATION_FAILED", "Failed to send initialization config");
    return;
  }

  is_initialized_ = true;
  
  result->Success(flutter::EncodableValue(flutter::EncodableMap{
    {"success", flutter::EncodableValue(true)},
    {"message", flutter::EncodableValue("MCP initialized successfully")}
  }));
}

void McpChannelPlugin::ProcessMessage(
    const flutter::EncodableMap& request,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  
  if (!is_initialized_) {
    result->Error("NOT_INITIALIZED", "MCP not initialized");
    return;
  }

  auto request_id_it = request.find(flutter::EncodableValue("requestId"));
  if (request_id_it == request.end()) {
    result->Error("MISSING_REQUEST_ID", "Request ID is required");
    return;
  }

  std::string request_id = std::get<std::string>(request_id_it->second);

  // Store the result for async response
  {
    std::lock_guard<std::mutex> lock(pending_requests_mutex_);
    pending_requests_[request_id] = std::move(result);
  }

  // Send message to Node.js
  std::string params_json = EncodableValueToJsonString(flutter::EncodableValue(request));
  std::string message = "{\"method\":\"processMessage\",\"params\":" + params_json + ",\"requestId\":\"" + request_id + "\"}";

  if (!node_process_->SendMessage(message)) {
    std::lock_guard<std::mutex> lock(pending_requests_mutex_);
    auto it = pending_requests_.find(request_id);
    if (it != pending_requests_.end()) {
      it->second->Error("SEND_FAILED", "Failed to send message to MCP process");
      pending_requests_.erase(it);
    }
  }
}

void McpChannelPlugin::StreamMessage(
    const flutter::EncodableMap& request,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  
  if (!is_initialized_) {
    result->Error("NOT_INITIALIZED", "MCP not initialized");
    return;
  }

  auto request_id_it = request.find(flutter::EncodableValue("requestId"));
  std::string request_id = request_id_it != request.end() ? 
    std::get<std::string>(request_id_it->second) : 
    "stream_" + std::to_string(std::chrono::steady_clock::now().time_since_epoch().count());

  // Send stream request to Node.js
  std::string params_json = EncodableValueToJsonString(flutter::EncodableValue(request));
  std::string message = "{\"method\":\"streamMessage\",\"params\":" + params_json + ",\"requestId\":\"" + request_id + "\"}";

  if (!node_process_->SendMessage(message)) {
    result->Error("SEND_FAILED", "Failed to send stream request to MCP process");
    return;
  }

  result->Success(flutter::EncodableValue(flutter::EncodableMap{
    {"success", flutter::EncodableValue(true)},
    {"message", flutter::EncodableValue("Stream started")}
  }));
}

void McpChannelPlugin::TestConnection(
    const flutter::EncodableMap& request,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  
  if (!is_initialized_) {
    result->Error("NOT_INITIALIZED", "MCP not initialized");
    return;
  }

  // For now, return mock success - will be replaced with actual test
  result->Success(flutter::EncodableValue(flutter::EncodableMap{
    {"connected", flutter::EncodableValue(true)},
    {"latency", flutter::EncodableValue(150)},
    {"metadata", flutter::EncodableValue(flutter::EncodableMap{})}
  }));
}

void McpChannelPlugin::GetCapabilities(
    const flutter::EncodableMap& request,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  
  if (!is_initialized_) {
    result->Error("NOT_INITIALIZED", "MCP not initialized");
    return;
  }

  // Mock capabilities - will be replaced with actual query
  result->Success(flutter::EncodableValue(flutter::EncodableMap{
    {"filesystem", flutter::EncodableValue(flutter::EncodableMap{
      {"tools", flutter::EncodableValue(flutter::EncodableList{"read_file", "write_file", "list_directory"})},
      {"resources", flutter::EncodableValue(flutter::EncodableList{"files"})},
      {"supportsProgress", flutter::EncodableValue(true)},
      {"supportsCancel", flutter::EncodableValue(false)}
    })}
  }));
}

void McpChannelPlugin::InjectContext(
    const flutter::EncodableMap& request,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  
  if (!is_initialized_) {
    result->Error("NOT_INITIALIZED", "MCP not initialized");
    return;
  }

  result->Success(flutter::EncodableValue(flutter::EncodableMap{
    {"success", flutter::EncodableValue(true)},
    {"message", flutter::EncodableValue("Context injected")}
  }));
}

void McpChannelPlugin::DisposeMcp(
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  
  if (node_process_) {
    node_process_->Stop();
  }

  is_initialized_ = false;
  
  result->Success(flutter::EncodableValue(flutter::EncodableMap{
    {"success", flutter::EncodableValue(true)},
    {"message", flutter::EncodableValue("MCP disposed")}
  }));
}

// Node.js message handling
void McpChannelPlugin::HandleNodeMessage(const std::string& message) {
  try {
    // Simple JSON parsing for type and requestId
    // In production, use a proper JSON parser
    
    if (message.find("\"type\":\"response\"") != std::string::npos) {
      // Extract requestId using simple string operations
      size_t req_id_start = message.find("\"requestId\":\"");
      if (req_id_start != std::string::npos) {
        req_id_start += 13; // Length of "requestId":"
        size_t req_id_end = message.find("\"", req_id_start);
        if (req_id_end != std::string::npos) {
          std::string request_id = message.substr(req_id_start, req_id_end - req_id_start);
          
          std::lock_guard<std::mutex> lock(pending_requests_mutex_);
          auto it = pending_requests_.find(request_id);
          if (it != pending_requests_.end()) {
            if (message.find("\"error\":") != std::string::npos && message.find("\"error\":null") == std::string::npos) {
              it->second->Error("MCP_ERROR", "Error processing request");
            } else {
              auto response_data = JsonStringToEncodableValue(message);
              it->second->Success(response_data);
            }
            pending_requests_.erase(it);
          }
        }
      }
    } else if (message.find("\"type\":\"event\"") != std::string::npos) {
      // Send event to Flutter via event channel
      if (stream_handler_ && stream_handler_->event_sink_) {
        auto event_data = JsonStringToEncodableValue(message);
        stream_handler_->event_sink_->Success(event_data);
      }
    }
  } catch (const std::exception& e) {
    std::cerr << "Error parsing Node.js message: " << e.what() << std::endl;
  }
}

// Utility methods
std::string McpChannelPlugin::GetMcpScriptPath() {
  // Get executable directory and construct path to MCP script
  char exe_path[MAX_PATH];
  GetModuleFileNameA(NULL, exe_path, MAX_PATH);
  
  std::string exe_dir = exe_path;
  size_t pos = exe_dir.find_last_of("\\/");
  if (pos != std::string::npos) {
    exe_dir = exe_dir.substr(0, pos);
  }
  
  // Path to the MCP script (relative to runner directory)
  return exe_dir + "\\mcp_bridge.js";
}

flutter::EncodableValue McpChannelPlugin::JsonStringToEncodableValue(const std::string& json_str) {
  // Simple JSON to EncodableValue conversion (placeholder implementation)
  // TODO: Replace with proper JSON parsing using nlohmann::json or similar
  
  // For now, just return the JSON string as data
  return flutter::EncodableValue(flutter::EncodableMap{
    {"data", flutter::EncodableValue(json_str)}
  });
}

std::string McpChannelPlugin::EncodableValueToJsonString(const flutter::EncodableValue& value) {
  // Simple JSON conversion - in production use proper JSON library
  std::ostringstream json_stream;
  
  if (auto map = std::get_if<flutter::EncodableMap>(&value)) {
    json_stream << "{";
    bool first = true;
    for (const auto& [key, val] : *map) {
      if (!first) json_stream << ",";
      first = false;
      
      std::string key_str = std::get<std::string>(key);
      json_stream << "\"" << key_str << "\":";
      
      if (auto str_val = std::get_if<std::string>(&val)) {
        json_stream << "\"" << *str_val << "\"";
      } else if (auto int_val = std::get_if<int32_t>(&val)) {
        json_stream << *int_val;
      } else if (auto bool_val = std::get_if<bool>(&val)) {
        json_stream << (*bool_val ? "true" : "false");
      } else if (auto double_val = std::get_if<double>(&val)) {
        json_stream << *double_val;
      } else {
        json_stream << "null";
      }
    }
    json_stream << "}";
  } else if (auto str = std::get_if<std::string>(&value)) {
    json_stream << "\"" << *str << "\"";
  } else {
    json_stream << "{}";
  }
  
  return json_stream.str();
}