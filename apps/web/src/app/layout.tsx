import type { Metadata } from 'next';
import { Space_Grotesk } from 'next/font/google';
import './globals.css';
import { Providers } from './providers';

const spaceGrotesk = Space_Grotesk({ subsets: ['latin'] });

export const metadata: Metadata = {
  title: 'CertaWeb3 | NFT Course Certificate',
  description: 'Provide an on-chain zero-knowledge proof of your developer curriculum.',
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en" suppressHydrationWarning className="dark">
      <body className={spaceGrotesk.className}>
        <Providers>
          {children}
        </Providers>
      </body>
    </html>
  );
}