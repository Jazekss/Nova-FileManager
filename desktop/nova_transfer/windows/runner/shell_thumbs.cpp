#include "shell_thumbs.h"

#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>
#include <objidl.h>
#include <shlobj.h>
#include <shobjidl.h>
#include <wincodec.h>
#include <windows.h>

#include <memory>
#include <string>
#include <vector>

namespace {

std::wstring Utf8ToWide(const std::string& s) {
  if (s.empty()) return std::wstring();
  int n = MultiByteToWideChar(CP_UTF8, 0, s.data(), (int)s.size(), nullptr, 0);
  std::wstring w(n, L'\0');
  MultiByteToWideChar(CP_UTF8, 0, s.data(), (int)s.size(), w.data(), n);
  return w;
}

template <typename T>
void SafeRelease(T*& p) {
  if (p) {
    p->Release();
    p = nullptr;
  }
}

bool ShellThumb(const std::wstring& path, int size, std::vector<uint8_t>& out) {
  IShellItemImageFactory* factory = nullptr;
  HBITMAP bmp = nullptr;
  IWICImagingFactory* wic = nullptr;
  IWICBitmap* wbmp = nullptr;
  IStream* stream = nullptr;
  IWICBitmapEncoder* enc = nullptr;
  IWICBitmapFrameEncode* frame = nullptr;
  IPropertyBag2* props = nullptr;
  bool ok = false;

  do {
    if (FAILED(SHCreateItemFromParsingName(path.c_str(), nullptr,
                                           IID_PPV_ARGS(&factory))))
      break;
    SIZE sz = {size, size};
    // THUMBNAILONLY: no generic file-type icons — the app draws its own.
    if (FAILED(factory->GetImage(
            sz, SIIGBF_THUMBNAILONLY | SIIGBF_BIGGERSIZEOK, &bmp)))
      break;
    if (FAILED(CoCreateInstance(CLSID_WICImagingFactory, nullptr,
                                CLSCTX_INPROC_SERVER, IID_PPV_ARGS(&wic))))
      break;
    if (FAILED(wic->CreateBitmapFromHBITMAP(bmp, nullptr, WICBitmapIgnoreAlpha,
                                            &wbmp)))
      break;
    if (FAILED(CreateStreamOnHGlobal(nullptr, TRUE, &stream))) break;
    if (FAILED(wic->CreateEncoder(GUID_ContainerFormatJpeg, nullptr, &enc)))
      break;
    if (FAILED(enc->Initialize(stream, WICBitmapEncoderNoCache))) break;
    if (FAILED(enc->CreateNewFrame(&frame, &props))) break;
    if (FAILED(frame->Initialize(props))) break;
    UINT w = 0, h = 0;
    wbmp->GetSize(&w, &h);
    frame->SetSize(w, h);
    WICPixelFormatGUID fmt = GUID_WICPixelFormat24bppBGR;
    frame->SetPixelFormat(&fmt);
    IWICFormatConverter* conv = nullptr;
    if (FAILED(wic->CreateFormatConverter(&conv))) break;
    HRESULT hr = conv->Initialize(wbmp, GUID_WICPixelFormat24bppBGR,
                                  WICBitmapDitherTypeNone, nullptr, 0.0,
                                  WICBitmapPaletteTypeCustom);
    if (SUCCEEDED(hr)) hr = frame->WriteSource(conv, nullptr);
    conv->Release();
    if (FAILED(hr)) break;
    if (FAILED(frame->Commit()) || FAILED(enc->Commit())) break;

    HGLOBAL mem = nullptr;
    if (FAILED(GetHGlobalFromStream(stream, &mem))) break;
    STATSTG st = {};
    stream->Stat(&st, STATFLAG_NONAME);
    const size_t len = (size_t)st.cbSize.QuadPart;
    void* data = GlobalLock(mem);
    if (!data) break;
    out.assign((uint8_t*)data, (uint8_t*)data + len);
    GlobalUnlock(mem);
    ok = !out.empty();
  } while (false);

  SafeRelease(props);
  SafeRelease(frame);
  SafeRelease(enc);
  SafeRelease(stream);
  SafeRelease(wbmp);
  SafeRelease(wic);
  if (bmp) DeleteObject(bmp);
  SafeRelease(factory);
  return ok;
}

}  // namespace

void RegisterShellThumbs(flutter::BinaryMessenger* messenger) {
  static std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>>
      channel;
  channel = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
      messenger, "nova/shell", &flutter::StandardMethodCodec::GetInstance());
  channel->SetMethodCallHandler(
      [](const flutter::MethodCall<flutter::EncodableValue>& call,
         std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>>
             result) {
        if (call.method_name() != "thumb") {
          result->NotImplemented();
          return;
        }
        const auto* args = std::get_if<flutter::EncodableMap>(call.arguments());
        if (!args) {
          result->Success();
          return;
        }
        std::string path;
        int size = 256;
        auto p = args->find(flutter::EncodableValue("path"));
        if (p != args->end()) {
          if (auto* s = std::get_if<std::string>(&p->second)) path = *s;
        }
        auto z = args->find(flutter::EncodableValue("size"));
        if (z != args->end()) {
          if (auto* i = std::get_if<int32_t>(&z->second)) size = *i;
        }
        std::vector<uint8_t> bytes;
        if (!path.empty() && ShellThumb(Utf8ToWide(path), size, bytes)) {
          result->Success(flutter::EncodableValue(bytes));
        } else {
          result->Success();
        }
      });
}
