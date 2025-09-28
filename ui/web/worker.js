self.onmessage = async function (e) {
  const { id, data } = e.data;

  try {
    console.log(`[Worker]: Decompressing ${id}`);

    // using the browser's native decompression API
    const stream = new Blob([data]).stream();
    const decompressedStream = stream.pipeThrough(
      new DecompressionStream("gzip"),
    );

    const response = new Response(decompressedStream);
    const decompressedData = await response.arrayBuffer();

    console.log(`[Worker]: Decompressed ${id}`);

    self.postMessage(
      {
        id: id,
        success: true,
        data: new Uint8Array(decompressedData),
      },
      [decompressedData],
    );
  } catch (error) {
    console.log(`[Worker]: Decompression failed ${id}`);
    self.postMessage({
      id: id,
      success: false,
      error: error.message,
    });
  }
};
