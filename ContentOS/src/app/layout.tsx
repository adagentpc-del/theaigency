import type { ReactNode } from 'react';

export const metadata = {
  title: 'theAIgincy Content OS',
  description: 'AI content distribution command center'
};

export default function RootLayout({ children }: { children: ReactNode }) {
  return <html lang="en"><body style={{margin:0,background:'#fafafa'}}>{children}</body></html>;
}
