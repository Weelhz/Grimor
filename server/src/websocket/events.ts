import { z } from 'zod';

// Client to Server Events
export const ProgressUpdateSchema = z.object({
  bookId: z.number(),
  presetId: z.number(),
  chapter: z.number(),
  pageFraction: z.number(),
  timestamp: z.number()
});

export const JoinBookRoomSchema = z.object({
  bookId: z.number(),
  presetId: z.number()
});

export const LeaveBookRoomSchema = z.object({
  bookId: z.number()
});

export const UserSettingsUpdateSchema = z.object({
  moodSensitivity: z.number().min(0.1).max(2.0).optional(),
  musicVolume: z.number().min(0).max(100).optional(),
  dynamicBg: z.boolean().optional(),
  theme: z.enum(['light', 'dark']).optional()
});

// Server to Client Events
export interface MoodTriggerEvent {
  moodName: string;
  tempo: number;
  backgroundImageUrl?: string;
  transitionType: 'fade' | 'crossfade' | 'jump';
  timestamp: number;
}

export interface SyncStatusEvent {
  status: 'connected' | 'disconnected' | 'syncing' | 'error';
  message?: string;
  timestamp: number;
}

export interface UserJoinedEvent {
  userId: number;
  username: string;
  timestamp: number;
}

export interface UserLeftEvent {
  userId: number;
  username: string;
  timestamp: number;
}

// Event Types
export type ClientToServerEvents = {
  'progress:update': (data: z.infer<typeof ProgressUpdateSchema>) => void;
  'room:join': (data: z.infer<typeof JoinBookRoomSchema>) => void;
  'room:leave': (data: z.infer<typeof LeaveBookRoomSchema>) => void;
  'settings:update': (data: z.infer<typeof UserSettingsUpdateSchema>) => void;
  'ping': () => void;
  'sync:event': (data: any) => void;
  'sync:status_request': () => void;
  'sync:recover': (data: any) => void;
  'mood:manual_trigger': (data: any) => void;
  'mood:preferences_update': (data: any) => void;
};

export type ServerToClientEvents = {
  'mood:trigger': (data: MoodTriggerEvent) => void;
  'sync:status': (data: SyncStatusEvent) => void;
  'user:joined': (data: UserJoinedEvent) => void;
  'user:left': (data: UserLeftEvent) => void;
  'pong': () => void;
  'error': (error: { message: string; code?: string }) => void;
  'sync:recovery': (data: any) => void;
};

export type InterServerEvents = {};

export type SocketData = {
  userId: number;
  username: string;
  currentBookId?: number | undefined;
  currentPresetId?: number | undefined;
  joinedAt: number;
};