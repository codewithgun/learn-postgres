import * as pg from "pg";

class Wallet {
	id: number;
	balance: string;
	name: string;
}

const pool = new pg.Pool({
	host: "localhost",
	port: 8432,
	database: "postgres",
	user: "postgres",
	password: "postgres",
	idleTimeoutMillis: 0, // Connection won't be disconnected forever, with performance gain without initiating TCP connection in exchange of RAM usage
	max: 20
});

async function withdraw(name: string, withdrawAmount: number) {
	let client = await pool.connect();
	await client.query("BEGIN TRANSACTION");
	let { id, balance } = (await client.query<Wallet>("SELECT id, balance FROM wallets WHERE name = $1", [name])).rows[0];
	let numBalance = Number.parseInt(balance); //BigNumber should be used
	//This should block overspending. However, it won't if there was concurrent incoming request
	if (numBalance > withdrawAmount) {
		await client.query("UPDATE wallets SET balance = balance - $1 WHERE id = $2", [withdrawAmount, id]);
		await client.query("COMMIT");
	} else {
		await client.query("ROLLBACK");
		console.error("Insufficient balance");
	}
}

//Spam withdraw
async function start(spam: number) {
	for (let i = 0; i < spam; i++) {
		withdraw("codewithgun", 50);
	}
}

start(100);
