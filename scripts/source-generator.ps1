param(
    [Parameter(Mandatory=$true)]
    [string]$folderPath
)

# Setup local types
Set-Content -Path "$folderPath/src/app.d.ts" -Value @"
declare global {
	namespace App {
		// interface Error {}
		interface Locals {
			user: import('lucia').User | null;
			session: import('lucia').Session | null;
		}
		// interface PageData {}
		// interface PageState {}
		// interface Platform {}
	}
}

export {};
"@

# Setup ambient types
Set-Content -Path "$folderPath/src/ambient.d.ts" -Value @"
type UserInfo = {
	firstName: string;
	lastName: string;
	email: string;
};
"@

# Setup server hooks
Set-Content -Path "$folderPath/src/hooks.server.ts" -Value @"
import { lucia } from '`$lib/server/auth';
import type { Handle } from '@sveltejs/kit';

export const handle: Handle = async ({ event, resolve }) => {
	const sessionId = event.cookies.get(lucia.sessionCookieName);
	if (!sessionId) {
		event.locals.user = null;
		event.locals.session = null;
		return resolve(event);
	}

	const { session, user } = await lucia.validateSession(sessionId);
	if (session && session.fresh) {
		const sessionCookie = lucia.createSessionCookie(session.id);
		event.cookies.set(sessionCookie.name, sessionCookie.value, {
			path: '.',
			...sessionCookie.attributes
		});
	}
	if (!session) {
		const sessionCookie = lucia.createBlankSessionCookie();
		event.cookies.set(sessionCookie.name, sessionCookie.value, {
			path: '.',
			...sessionCookie.attributes
		});
	}

	event.locals.user = user;
	event.locals.session = session;
	return resolve(event);
};
"@

New-item -Path "$folderPath/src/lib/server","$folderPath/src/lib/server/db", "$folderPath/src/lib/server/db/schema" -ItemType Directory

# Write auth file
if (!(Test-Path -Path "$folderPath/src/lib/server/auth.ts")) {
Set-Content -Path "$folderPath/src/lib/server/auth.ts" -Value @"
import { GITHUB_CLIENT_ID, GITHUB_CLIENT_SECRET } from '`$env/static/private';
import { DrizzleSQLiteAdapter } from '@lucia-auth/adapter-drizzle';
import { redirect } from '@sveltejs/kit';
import { GitHub } from 'arctic';
import { Lucia } from 'lucia';
import { db } from './db';
import { session, user } from './db/schema/user';

const adapter = new DrizzleSQLiteAdapter(db, session, user);

export const github = new GitHub(GITHUB_CLIENT_ID, GITHUB_CLIENT_SECRET);

export const lucia = new Lucia(adapter, {
	sessionCookie: {
		attributes: {
			secure: process.env.NODE_ENV === 'production'
		}
	},
	getUserAttributes: (data) => {
		return {
			firstName: data.firstName,
			lastName: data.lastName,
			email: data.email,
			role: data.role,
			avatarUrl: data.avatarUrl
		};
	}
});

declare module 'lucia' {
	interface Register {
		Lucia: typeof lucia;
		DatabaseUserAttributes: {
			firstName: string;
			lastName: string;
			role: string;
			email: string;
			avatarUrl: string;
		};
	}
}
"@
}

# Write db file
if (!(Test-Path -Path "$folderPath/src/lib/server/db/index.ts")) {
Set-Content -Path "$folderPath/src/lib/server/db/index.ts" -Value @"
import 'dotenv/config';
import * as schema from './schema';
import { drizzle } from 'drizzle-orm/libsql';
import { createClient } from '@libsql/client';

const config = process.env.TURSO_CONFIG;
const local = process.env.TURSO_LOCAL;
const connectionUrl = process.env.TURSO_CONNECTION_URL;
const url = config === 'dev' ? local : connectionUrl;

const client = createClient({
	url: url!,
	authToken: process.env.TURSO_AUTH_TOKEN!
});
export const db = drizzle(client, { schema });

"@
}

# Write schema file
if (!(Test-Path -Path "$folderPath/src/lib/server/db/schema/index.ts")) {
Set-Content -Path "$folderPath/src/lib/server/db/schema/index.ts" -Value @"
export * from './user';
"@
}

# Write user file
if (!(Test-Path -Path "$folderPath/src/lib/server/db/schema/user.ts")) {
Set-Content -Path "$folderPath/src/lib/server/db/schema/user.ts" -Value @"
import { relations } from 'drizzle-orm';
import { integer, primaryKey, sqliteTable, text } from 'drizzle-orm/sqlite-core';

export const user = sqliteTable(
	'users',
	{
		id: text('id', { length: 100 }).unique().notNull(),
		provider: text('provider', { enum: ['google', 'github', 'manual'] }).notNull(),
		providerId: text('provider_id', { length: 255 }).notNull(),
		firstName: text('first_name', { length: 100 }).notNull(),
		lastName: text('last_name', { length: 100 }).notNull(),
		role: text('role', { enum: ['customer', 'store_owner', 'admin'] }).notNull(),
		email: text('email', { length: 100 }).notNull(),
		username: text('username', { length: 100 }).notNull(),
		hashPassword: text('hash_password', { length: 255 }),
		avatarUrl: text('avatar_url', { length: 255 })
	},
	(table) => {
		return {
			pk: primaryKey({ columns: [table.id] })
		};
	}
);

export const session = sqliteTable('sessions', {
	id: text('id', { length: 100 }).primaryKey(),
	userId: text('user_id', { length: 100 }).notNull(),
	expiresAt: integer('expires_at').notNull()
});

export const userRelations = relations(user, ({ many }) => ({
	sessions: many(session)
}));

export const sessionRelations = relations(session, ({ one }) => ({
	user: one(user, {
		fields: [session.userId],
		references: [user.id]
	})
}));

"@
}
