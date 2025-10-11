import { Request, Response } from 'express';
import { Connection, Keypair, PublicKey } from '@solana/web3.js';
import { getOrCreateAssociatedTokenAccount, transfer, TOKEN_2022_PROGRAM_ID } from '@solana/spl-token';
import dotenv from 'dotenv';

dotenv.config();

export const transferEquinox = async (req: Request, res: Response) => {
  const { payerSecretArray, recipientWalletAddress, amount } = req.body;

  // Validate request body
  if (!payerSecretArray || !Array.isArray(payerSecretArray)) {
    return res.status(400).json({ error: 'Invalid or missing payerSecretArray' });
  }
  if (!recipientWalletAddress || typeof recipientWalletAddress !== 'string') {
    return res.status(400).json({ error: 'Invalid or missing recipientWalletAddress' });
  }
  if (!amount || typeof amount !== 'number' || amount <= 0) {
    return res.status(400).json({ error: 'Invalid or missing amount' });
  }

  const connection = new Connection(process.env.SOLANA_NETWORK!, 'confirmed');
  const mintAddress = new PublicKey(process.env.EQUINOX_MINT_ADDRESS!);
  const payerSecretKey = Uint8Array.from(payerSecretArray);
  const payer = Keypair.fromSecretKey(payerSecretKey);
  const distributorWallet = payer.publicKey;
  const recipientWallet = new PublicKey(recipientWalletAddress);

  try {
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

    console.log('Payer Token Account:', distributorTokenAccount.address.toBase58());
    console.log('Recipient Token Account:', recipientTokenAccount.address.toBase58());

    await transfer(
      connection,
      payer,
      distributorTokenAccount.address,
      recipientTokenAccount.address,
      payer.publicKey,
      BigInt(amount) * BigInt(Math.pow(10, 9)),
      [],
      undefined,
      TOKEN_2022_PROGRAM_ID
    );

    res.json({
      message: `Successfully transferred ${amount} Equinox tokens from ${distributorWallet.toBase58()} to ${recipientWallet.toBase58()}`,
      recipientWallet: recipientWallet.toBase58(),
      recipientTokenAccount: recipientTokenAccount.address.toBase58()
    });
  } catch (error) {
    console.error('Error during Equinox token transfer:', error);
    res.status(500).json({ error: (error as any).message });
  }
};