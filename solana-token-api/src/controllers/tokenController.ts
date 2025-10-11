import { Request, Response } from 'express';
import { Connection, Keypair, PublicKey, LAMPORTS_PER_SOL } from '@solana/web3.js';
import { getOrCreateAssociatedTokenAccount, getAssociatedTokenAddress, transfer, getAccount, getMint, TOKEN_2022_PROGRAM_ID } from '@solana/spl-token';
import dotenv from 'dotenv';

dotenv.config();



export const createEquinoxWallet = async (req: Request, res: Response) => {
  const connection = new Connection(process.env.SOLANA_NETWORK!, 'confirmed');
  const payer = Keypair.generate(); // Generate a new wallet
  const walletPublicKey = payer.publicKey.toBase58();
  const walletPrivateKeyArray = Array.from(payer.secretKey);

  try {
    // Attempt to airdrop SOL to the new wallet
    const airdropSignature = await connection.requestAirdrop(payer.publicKey, LAMPORTS_PER_SOL);
    await connection.confirmTransaction(airdropSignature, 'confirmed');

    res.json({
      message: 'Wallet created successfully and SOL airdropped.',
      walletPublicKey,
      walletPrivateKeyArray,
      airdropStatus: 'Success',
    });
  } catch (error) {
    console.error('Airdrop failed:', error);

    res.json({
      message: 'Wallet created successfully, but airdrop failed. Please manually airdrop SOL to the wallet.',
      walletPublicKey,
      walletPrivateKeyArray,
      airdropStatus: 'Failed',
      airdropInstructions: `Use the following command to manually airdrop SOL:\nsolana airdrop 1 ${walletPublicKey}`,
    });
  }
};




export const getEquinoxBalance = async (req: Request, res: Response) => {
  const { walletAddress } = req.params; // Get wallet address from request parameters
  const connection = new Connection(process.env.SOLANA_NETWORK!, 'confirmed');
  const mintAddress = new PublicKey(process.env.EQUINOX_MINT_ADDRESS!); // Use Equinox mint address

  try {
    const walletPublicKey = new PublicKey(walletAddress);

    // Derive the associated token account for the wallet and mint
    const tokenAccountAddress = await getAssociatedTokenAddress(
      mintAddress,
      walletPublicKey,
      false, // Not a PDA (Program Derived Address)
      TOKEN_2022_PROGRAM_ID
    );

    // Fetch the token account details
    const tokenAccount = await getAccount(
      connection,
      tokenAccountAddress,
      undefined,
      TOKEN_2022_PROGRAM_ID
    );

    // Fetch mint details to calculate the balance
    const mint = await getMint(connection, mintAddress, undefined, TOKEN_2022_PROGRAM_ID);
    const balance = Number(tokenAccount.amount) / Math.pow(10, mint.decimals);

    res.json({
      walletAddress: walletPublicKey.toBase58(),
      tokenAccountAddress: tokenAccountAddress.toBase58(),
      balance,
      mintAddress: mintAddress.toBase58()
    });
  } catch (error) {
    console.error('Error retrieving Equinox balance:', error);

    // Handle the case where the associated token account does not exist
    if (error instanceof Error && error.message.includes('Failed to find account')) {
      return res.status(404).json({
        error: 'No associated token account found for the provided wallet address and mint address.',
        walletAddress,
        mintAddress: mintAddress.toBase58()
      });
    }
    
    res.status(500).json({ error: (error as any).message });
  }
};


export const transferToken = async (req: Request, res: Response) => {
  const { multiplier } = req.body;
  const connection = new Connection(process.env.SOLANA_NETWORK!, 'confirmed');
  const mintAddress = new PublicKey(process.env.MINT_ADDRESS!);
  const payerSecretKey = Uint8Array.from(JSON.parse(process.env.PAYER_SECRET_KEY!));
  const payer = Keypair.fromSecretKey(payerSecretKey);
  const distributorWallet = new PublicKey(process.env.DISTRIBUTOR_WALLET!);
  const recipient = Keypair.generate();

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
      recipient.publicKey,
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

    // Transfer tokens to recipient
    await transfer(
      connection,
      payer,
      distributorTokenAccount.address,
      recipientTokenAccount.address,
      payer.publicKey,
      BigInt(1000 * multiplier) * BigInt(Math.pow(10, mint.decimals)),
      [],
      undefined,
      TOKEN_2022_PROGRAM_ID
    );

    res.json({
      recipientWallet: recipient.publicKey.toBase58(),
      recipientTokenAccount: recipientTokenAccount.address.toBase58()
    });
  } catch (error) {
    console.error('Error during token transfer:', error);
    res.status(500).json({ error: (error as any).message });
  }
};