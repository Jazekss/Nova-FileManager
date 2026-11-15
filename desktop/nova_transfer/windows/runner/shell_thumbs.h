#ifndef RUNNER_SHELL_THUMBS_H_
#define RUNNER_SHELL_THUMBS_H_

#include <flutter/binary_messenger.h>

// Registers the "nova/shell" channel: method "thumb" {path, size}
// returns a JPEG thumbnail from the Windows Shell (the same thumbnails
// Explorer shows: photos incl. HEIC with the codec, videos, PDFs…) or
// null when the file has no thumbnail.
void RegisterShellThumbs(flutter::BinaryMessenger* messenger);

#endif  // RUNNER_SHELL_THUMBS_H_
