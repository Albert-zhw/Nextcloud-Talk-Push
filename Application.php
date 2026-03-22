<?php
declare(strict_types=1);

namespace OCA\TalkPush\AppInfo;

use OCA\Talk\Events\ChatMessageSentEvent;
use OCA\TalkPush\Listener\ChatMessageListener;
use OCP\AppFramework\App;
use OCP\AppFramework\Bootstrap\IBootContext;
use OCP\AppFramework\Bootstrap\IBootstrap;
use OCP\AppFramework\Bootstrap\IRegistrationContext;
use OCP\EventDispatcher\IEventDispatcher;

class Application extends App implements IBootstrap {
    public const APP_ID = 'talkpush';

    public function __construct() {
        parent::__construct(self::APP_ID);
    }

    public function register(IRegistrationContext $context): void {
    }

    public function boot(IBootContext $context): void {
        $context->injectFn([$this, 'attachHooks']);
    }

    public function attachHooks(IEventDispatcher $eventDispatcher): void {
        $eventDispatcher->addListener(ChatMessageSentEvent::class, function(ChatMessageSentEvent $event) {
            $listener = new ChatMessageListener();
            $listener->handle($event);
        });
    }
}
