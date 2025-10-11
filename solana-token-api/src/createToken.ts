import { Connection, Keypair, LAMPORTS_PER_SOL } from '@solana/web3.js';
import { createMint, getOrCreateAssociatedTokenAccount, mintTo, TOKEN_2022_PROGRAM_ID } from '@solana/spl-token';
import fs from 'fs';
import path from 'path';
import dotenv from 'dotenv';

dotenv.config();

const sleep = (ms: number) => new Promise(resolve => setTimeout(resolve, ms));

(async () => {
  const connection = new Connection(process.env.SOLANA_NETWORK!, 'confirmed');
  let payer: Keypair;

  if (process.env.PAYER_SECRET_KEY) {
    const payerSecretKey = Uint8Array.from(JSON.parse(process.env.PAYER_SECRET_KEY));
    payer = Keypair.fromSecretKey(payerSecretKey);
  } else {
    payer = Keypair.generate();
    fs.appendFileSync(path.join(__dirname, '../.env'), `PAYER_SECRET_KEY=${JSON.stringify(Array.from(payer.secretKey))}\n`);
  }

  const mintAuthority = Keypair.generate();
  const distributor = Keypair.generate();

  console.log('Payer Public Key:', payer.publicKey.toBase58());

  while (true) {
    const balance = await connection.getBalance(payer.publicKey);
    if (balance >= LAMPORTS_PER_SOL) {
      break;
    }

    console.log('Insufficient balance. Please manually add SOL to the payer\'s wallet using the following address:');
    console.log(payer.publicKey.toBase58());
    await sleep(10000); // Wait for 10 seconds before checking again
  }

  // Create new token mint
  const mint = await createMint(
    connection,
    payer,
    mintAuthority.publicKey,
    null,
    9, // Decimals
    undefined,
    undefined,
    TOKEN_2022_PROGRAM_ID
  );

  // Create distributor token account
  const distributorTokenAccount = await getOrCreateAssociatedTokenAccount(
    connection,
    payer,
    mint,
    distributor.publicKey,
    true,
    undefined,
    undefined,
    TOKEN_2022_PROGRAM_ID
  );

  // Mint tokens to distributor
  await mintTo(
    connection,
    payer,
    mint,
    distributorTokenAccount.address,
    mintAuthority,
    1000000, // Amount of tokens to mint
    [],
    undefined,
    TOKEN_2022_PROGRAM_ID
  );

  console.log('Mint Address:', mint.toBase58());
  console.log('Distributor Wallet:', distributor.publicKey.toBase58());

  // Save details to .env file
  const envPath = path.join(__dirname, '../.env');
  fs.appendFileSync(envPath, `MINT_ADDRESS=${mint.toBase58()}\n`);
  fs.appendFileSync(envPath, `DISTRIBUTOR_WALLET=${distributor.publicKey.toBase58()}\n`);
})();