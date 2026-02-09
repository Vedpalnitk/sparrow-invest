export const NOTIFICATION_EVENTS = {
  TRADE_CREATED: 'notification.trade.created',
  TRADE_STATUS_UPDATED: 'notification.trade.status_updated',
  CLIENT_TRADE_REQUEST: 'notification.client.trade_request',
  SIP_FAILED: 'notification.sip.failed',
  SIP_CREATED: 'notification.sip.created',
} as const;

export interface NotificationPayload {
  userId: string;
  category: string;
  title: string;
  body: string;
  metadata?: Record<string, any>;
}
