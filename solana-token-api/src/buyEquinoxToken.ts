import { Request, Response } from 'express';
import { Connection, Keypair, PublicKey } from '@solana/web3.js';
import { getOrCreateAssociatedTokenAccount, transfer, TOKEN_2022_PROGRAM_ID } from '@solana/spl-token';
import dotenv from 'dotenv';

dotenv.config();

export const buyEquinoxToken = async (req: Request, res: Response) => {
  const { recipientWalletAddress, amount } = req.body; // Get recipient and amount from the request body
  const connection = new Connection(process.env.SOLANA_NETWORK!, 'confirmed');
  const mintAddress = new PublicKey(process.env.EQUINOX_MINT_ADDRESS!); // Use a specific mint address for Equinox
  const payerSecretKey = Uint8Array.from(JSON.parse(process.env.PAYER_SECRET_KEY!));
  const payer = Keypair.fromSecretKey(payerSecretKey);
  const distributorWallet = payer.publicKey; // Use the payer as the distributor
  const recipientWallet = new PublicKey(recipientWalletAddress); // Dynamic recipient wallet

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

    // Transfer tokens to recipient
    await transfer(
      connection,
      payer,
      distributorTokenAccount.address,
      recipientTokenAccount.address,
      payer.publicKey,
      BigInt(amount) * BigInt(Math.pow(10, 9)), // Assuming 9 decimals
      [],
      undefined,
      TOKEN_2022_PROGRAM_ID
    );

    res.json({
      message: `Successfully transferred ${amount} Equinox tokens to ${recipientWallet.toBase58()}`,
      recipientWallet: recipientWallet.toBase58(),
      recipientTokenAccount: recipientTokenAccount.address.toBase58()
    });
  } catch (error) {
    console.error('Error during Equinox token transfer:', error);
    res.status(500).json({ error: (error as any).message });
  }
};