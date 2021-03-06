import ceylon.interop.java {
    toByteArray
}
import ceylon.io.buffer {
    newByteBufferWithData
}
import ceylon.net.http.server.websocket {
    WebSocketChannel,
    WebSocketEndpoint,
    CloseReason,
    NoReason
}

import io.undertow.websockets.core {
    AbstractReceiveListener,
    BufferedTextMessage,
    UtWebSocketChannel=WebSocketChannel,
    BufferedBinaryMessage,
    WebSockets {
        sendCloseBlocking
    },
    UTF8Output
}

import java.nio {
    JByteBuffer=ByteBuffer {
        wrapByteBuffer=wrap
    }
}

import org.xnio {
    IoUtils {
        safeClose
    }
}

by("Matej Lazar")
class CeylonWebSocketFrameHandler(WebSocketEndpoint webSocketEndpoint, WebSocketChannel webSocketChannel)
        extends AbstractReceiveListener() {

    shared actual void onFullTextMessage(UtWebSocketChannel channel, BufferedTextMessage message) 
            => webSocketEndpoint.onText(webSocketChannel, message.data );

    shared actual void onFullBinaryMessage(UtWebSocketChannel channel, BufferedBinaryMessage message) 
            => webSocketEndpoint.onBinary(webSocketChannel, 
                    newByteBufferWithData(*toByteArray(message.toByteArray())));

    shared actual void onFullCloseMessage(UtWebSocketChannel channel, BufferedBinaryMessage message) {
        JByteBuffer buffer = wrapByteBuffer(message.toByteArray());

        if (buffer.remaining() > 2) {
            Integer code = buffer.short;
            String reason = UTF8Output(buffer).extract();
            webSocketEndpoint.onClose(webSocketChannel, CloseReason(code, reason));
        } else {
            webSocketEndpoint.onClose(webSocketChannel, NoReason());
        }
        sendCloseBlocking(message.data, channel);
    }

    shared actual void onError(UtWebSocketChannel channel, Throwable error) {
        webSocketEndpoint.onError(webSocketChannel, error);
        safeClose(channel);
    }
}
