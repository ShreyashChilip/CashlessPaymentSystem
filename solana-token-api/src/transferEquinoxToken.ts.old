import { Connection, Keypair, PublicKey } from '@solana/web3.js';
import { getOrCreateAssociatedTokenAccount, transfer, getAccount, getMint, TOKEN_2022_PROGRAM_ID } from '@solana/spl-token';
import dotenv from 'dotenv';

dotenv.config();

const transferEquinoxToken = async () => {
  const connection = new Connection(process.env.SOLANA_NETWORK!, 'confirmed');
  const mintAddress = new PublicKey('mnts9NMk2ZPtcUjtcRtHgXz2ungkrrCQzXsCFPTGTae');
  const distributorWallet = new PublicKey('kiQR5Wuj9qHegtDnH1aumUX9SbDt5haN6kirmUrStdo');
  const recipientWallet = new PublicKey('8iXrWkKcLTdgtpWyXMxNEwg4cscsWeEEfct58B8ZvZgN');
  const payerSecretKey = Uint8Array.from(JSON.parse(process.env.PAYER_SECRET_KEY!));
  const payer = Keypair.fromSecretKey(payerSecretKey);

  try {
    // Ensure distributor token account is initialized
    const distributorTokenAccount = await getOrCreateAssociatedTokenAccount(
      connection,
      payer,
      mintAddress,
      distributorWallet,
      true,
      undefined,
      undefined,
      TOKEN_2022_PROGRAM_ID
    );

    // Ensure recipient token account is initialized
    const recipientTokenAccount = await getOrCreateAssociatedTokenAccount(
      connection,
      payer,
      mintAddress,
      recipientWallet,
      true,
      undefined,
      undefined,
      TOKEN_2022_PROGRAM_ID
    );

    // Log account details
    console.log('Distributor Token Account:', distributorTokenAccount.address.toBase58());
    console.log('Recipient Token Account:', recipientTokenAccount.address.toBase58());

    // Check distributor token balance
    const distributorTokenBalance = await getAccount(connection, distributorTokenAccount.address, undefined, TOKEN_2022_PROGRAM_ID);
    const mint = await getMint(connection, mintAddress, undefined, TOKEN_2022_PROGRAM_ID);
    const balance = Number(distributorTokenBalance.amount) / Math.pow(10, mint.decimals);
    console.log(`Distributor Token Balance: ${balance}`);

    // Ensure sufficient balance
    const amountToTransfer = 1000; // Adjust the amount as needed
    if (balance < amountToTransfer) {
      throw new Error('Insufficient funds in distributor token account');
    }

    // Transfer tokens to recipient
    await transfer(
      connection,
      payer,
      distributorTokenAccount.address,
      recipientTokenAccount.address,
      payer.publicKey,
      BigInt(amountToTransfer) * BigInt(Math.pow(10, mint.decimals)),
      [],
      undefined,
      TOKEN_2022_PROGRAM_ID
    );

    console.log(`Successfully transferred ${amountToTransfer} Equinox tokens to ${recipientWallet.toBase58()}`);
  } catch (error) {
    console.error('Error during token transfer:', error);
  }
};

transferEquinoxToken();