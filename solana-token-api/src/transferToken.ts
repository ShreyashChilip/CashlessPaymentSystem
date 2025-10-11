import { Request, Response } from 'express';
import { Connection, Keypair, PublicKey } from '@solana/web3.js';
import { getOrCreateAssociatedTokenAccount, transfer, TOKEN_2022_PROGRAM_ID } from '@solana/spl-token';
import dotenv from 'dotenv';

dotenv.config();

export const transferToken = async (req: Request, res: Response) => {
  const { recipientWalletAddress, amount, multiplier } = req.body;
  const connection = new Connection(process.env.SOLANA_NETWORK!, 'confirmed');
  const mintAddress = new PublicKey(process.env.MINT_ADDRESS!);
  const payerSecretKey = Uint8Array.from(JSON.parse(process.env.PAYER_SECRET_KEY!));
  const payer = Keypair.fromSecretKey(payerSecretKey);
  const distributorWallet = payer.publicKey; // Use the payer as the distributor
  const recipientWallet = new PublicKey(recipientWalletAddress);

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

    // Create recipient token account
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
      BigInt(amount * multiplier) * BigInt(Math.pow(10, 9)), // Assuming 9 decimals
      [],
      undefined,
      TOKEN_2022_PROGRAM_ID
    );

    res.json({
      recipientWallet: recipientWallet.toBase58(),
      recipientTokenAccount: recipientTokenAccount.address.toBase58()
    });
  } catch (error) {
    console.error('Error during token transfer:', error);
    res.status(500).json({ error: (error as any).message });
  }
};