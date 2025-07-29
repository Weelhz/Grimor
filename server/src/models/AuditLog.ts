import { query } from '../config/db';

export interface AuditLog {
  id: string;
  user_id?: string;
  action: string;
  resource_type?: string;
  resource_id?: string;
  details?: Record<string, any>;
  ip_address?: string;
  user_agent?: string;
  created_at: Date;
}

export interface CreateAuditLogData {
  user_id?: string;
  action: string;
  resource_type?: string;
  resource_id?: string;
  details?: Record<string, any>;
  ip_address?: string;
  user_agent?: string;
}

export const createAuditLog = async (auditData: CreateAuditLogData): Promise<AuditLog> => {
  const result = await query(`
    INSERT INTO audit_log (user_id, action, resource_type, resource_id, details, ip_address, user_agent)
    VALUES ($1, $2, $3, $4, $5, $6, $7)
    RETURNING *
  `, [
    auditData.user_id,
    auditData.action,
    auditData.resource_type,
    auditData.resource_id,
    auditData.details ? JSON.stringify(auditData.details) : null,
    auditData.ip_address,
    auditData.user_agent
  ]);

  return result.rows[0];
};

export const findAuditLogsByUser = async (userId: string, limit: number = 100): Promise<AuditLog[]> => {
  const result = await query(`
    SELECT * FROM audit_log 
    WHERE user_id = $1 
    ORDER BY created_at DESC 
    LIMIT $2
  `, [userId, limit]);
  return result.rows;
};

export const findAuditLogsByResource = async (resourceType: string, resourceId: string, limit: number = 100): Promise<AuditLog[]> => {
  const result = await query(`
    SELECT * FROM audit_log 
    WHERE resource_type = $1 AND resource_id = $2 
    ORDER BY created_at DESC 
    LIMIT $3
  `, [resourceType, resourceId, limit]);
  return result.rows;
};

export const findAuditLogsByAction = async (action: string, limit: number = 100): Promise<AuditLog[]> => {
  const result = await query(`
    SELECT * FROM audit_log 
    WHERE action = $1 
    ORDER BY created_at DESC 
    LIMIT $2
  `, [action, limit]);
  return result.rows;
};

export const findRecentAuditLogs = async (limit: number = 100): Promise<AuditLog[]> => {
  const result = await query(`
    SELECT * FROM audit_log 
    ORDER BY created_at DESC 
    LIMIT $1
  `, [limit]);
  return result.rows;
};