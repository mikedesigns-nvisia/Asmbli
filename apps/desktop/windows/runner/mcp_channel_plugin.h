#ifndef RUNNER_MCP_CHANNEL_PLUGIN_H_
#define RUNNER_MCP_CHANNEL_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>
#include <flutter/event_channel.h>
#include <flutter/event_stream_handler.h>
#include <flutter/binary_messenger.h>
#include <flutter_windows.h>

#include <memory>
#include <string>
#include <map>
#include <functional>
#include <thread>
#include <mutex>
#include <condition_variable>

class McpChannelPlugin {
 public:
  static void RegisterWithRegistrar(FlutterDesktopPluginRegistrarRef registrar);

  McpChannelPlugin();

  virtual ~McpChannelPlugin();

 private:
  // Method channel handler
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue>& method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

  // Event channel for streaming
  class McpEventStreamHandler : public flutter::StreamHandler<flutter::EncodableValue> {
   public:
    McpEventStreamHandler(McpChannelPlugin* plugin);
    virtual ~McpEventStreamHandler();

   protected:
    std::unique_ptr<flutter::StreamHandlerError<flutter::EncodableValue>> 
    OnListenInternal(
        const flutter::EncodableValue* arguments,
        std::unique_ptr<flutter::EventSink<flutter::EncodableValue>>&& events) override;

    std::unique_ptr<flutter::StreamHandlerError<flutter::EncodableValue>>
    OnCancelInternal(const flutter::EncodableValue* arguments) override;

   public:
    // Make event_sink_ accessible to the parent plugin
    std::unique_ptr<flutter::EventSink<flutter::EncodableValue>> event_sink_;
    
   private:
    McpChannelPlugin* plugin_;
  };

  // Node.js process management
  class NodeJsProcess {
   public:
    NodeJsProcess();
    ~NodeJsProcess();

    bool Start(const std::string& script_path);
    void Stop();
    bool IsRunning() const;
    
    // Send JSON message to Node.js process
    bool SendMessage(const std::string& message);
    
    // Set callback for receiving messages from Node.js
    void SetMessageCallback(std::function<void(const std::string&)> callback);

   private:
    void ReadOutputThread();
    void ReadErrorThread();
    
    HANDLE child_stdin_write_;
    HANDLE child_stdout_read_;
    HANDLE child_stderr_read_;
    PROCESS_INFORMATION process_info_;
    bool is_running_;
    std::thread output_thread_;
    std::thread error_thread_;
    std::function<void(const std::string&)> message_callback_;
    std::mutex callback_mutex_;
  };

  // MCP operations
  void InitializeMcp(const flutter::EncodableMap& config,
                     std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
  
  void ProcessMessage(const flutter::EncodableMap& request,
                      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
  
  void StreamMessage(const flutter::EncodableMap& request,
                     std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
  
  void TestConnection(const flutter::EncodableMap& request,
                      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
  
  void GetCapabilities(const flutter::EncodableMap& request,
                       std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
  
  void InjectContext(const flutter::EncodableMap& request,
                     std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

  void DisposeMcp(std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

  // Node.js message handling
  void HandleNodeMessage(const std::string& message);
  
  // Utility methods
  std::string GetMcpScriptPath();
  flutter::EncodableValue JsonStringToEncodableValue(const std::string& json_str);
  std::string EncodableValueToJsonString(const flutter::EncodableValue& value);

  // Members
  std::unique_ptr<flutter::BinaryMessenger> binary_messenger_;
  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> method_channel_;
  std::unique_ptr<flutter::EventChannel<flutter::EncodableValue>> event_channel_;
  std::unique_ptr<McpEventStreamHandler> stream_handler_;
  std::unique_ptr<NodeJsProcess> node_process_;
  
  // Pending requests management
  std::map<std::string, std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>>> pending_requests_;
  std::mutex pending_requests_mutex_;
  
  bool is_initialized_;
  std::string mcp_script_path_;
};

#endif  // RUNNER_MCP_CHANNEL_PLUGIN_H_