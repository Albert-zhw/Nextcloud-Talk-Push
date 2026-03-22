<?php
declare(strict_types=1);

namespace OCA\TalkPush\Listener;

use OCA\Talk\Events\ChatMessageSentEvent;

class ChatMessageListener {
    private const HUIXIAO_API_URL = 'https://x.2im.cn/push/v2';
    private const HUIXIAO_CID = 'YOUR_CID_HERE'; // TODO: 替换为您的回逍 CID（在 https://x.2im.cn 获取）
    private const HUIXIAO_ICON = 'https://example.com/your-icon.png'; // TODO: 替换为您自定义的图标 URL
    private const LOG_FILE = '/tmp/talkpush.log';
    
    // 不推送的用户 ID 列表（自己发送的消息不推送）
    private const EXCLUDED_USER_IDS = ['your_username']; // TODO: 替换为您的用户名

    public function handle(ChatMessageSentEvent $event): void {
        try {
            $comment = $event->getComment();
            $message = $comment->getMessage();
            $actorId = $comment->getActorId();
            
            // 空消息不推送
            if (empty($message)) {
                return;
            }
            
            // 如果是自己发的消息，不推送
            if (in_array($actorId, self::EXCLUDED_USER_IDS, true)) {
                return;
            }
            
            // 构建推送数据（标题显示发件人，内容显示实际消息）
            $pushData = [
                'cid' => self::HUIXIAO_CID,
                'group' => 'Nextcloud',
                'title' => "📬 {$actorId}",  // 标题显示发件人
                'content' => $message,  // 内容显示完整消息（不添加时间戳）
                'icon' => self::HUIXIAO_ICON
            ];

            // 记录日志（仅用于调试）
            $timestamp = date('Y-m-d H:i:s');
            $logEntry = "{$timestamp} - Message from '{$actorId}'\n";
            file_put_contents(self::LOG_FILE, $logEntry, FILE_APPEND);
            
            $logEntry = "{$timestamp} - Push sent: " . json_encode($pushData, JSON_UNESCAPED_UNICODE) . "\n";
            file_put_contents(self::LOG_FILE, $logEntry, FILE_APPEND);

            // 发送到回逍
            $ch = curl_init(self::HUIXIAO_API_URL);
            curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
            curl_setopt($ch, CURLOPT_POST, true);
            curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($pushData, JSON_UNESCAPED_UNICODE));
            curl_setopt($ch, CURLOPT_HTTPHEADER, ['Content-Type: application/json; charset=utf-8']);
            curl_setopt($ch, CURLOPT_TIMEOUT, 10);
            curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);
            
            $response = curl_exec($ch);
            $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
            curl_close($ch);

            $logEntry = "{$timestamp} - Result: HTTP {$httpCode} - {$response}\n";
            file_put_contents(self::LOG_FILE, $logEntry, FILE_APPEND);
            
        } catch (\Exception $e) {
            $logEntry = date('Y-m-d H:i:s') . " - ERROR: " . $e->getMessage() . "\n";
            file_put_contents(self::LOG_FILE, $logEntry, FILE_APPEND);
        }
    }
}
