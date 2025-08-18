import { useEffect, useState } from 'react';

interface CoolBackgroundProps {
  intensity?: 'subtle' | 'medium' | 'high';
  interactive?: boolean;
  className?: string;
}

export function CoolBackground({ 
  intensity = 'medium', 
  interactive = false, 
  className = '' 
}: CoolBackgroundProps) {
  const [mousePos, setMousePos] = useState({ x: 0, y: 0 });

  useEffect(() => {
    if (!interactive) return;

    const handleMouseMove = (e: MouseEvent) => {
      setMousePos({
        x: (e.clientX / window.innerWidth) * 100,
        y: (e.clientY / window.innerHeight) * 100
      });
    };

    window.addEventListener('mousemove', handleMouseMove);
    return () => window.removeEventListener('mousemove', handleMouseMove);
  }, [interactive]);

  const getIntensityStyles = () => {
    switch (intensity) {
      case 'subtle':
        return {
          primary: 'rgba(99, 102, 241, 0.05)',
          secondary: 'rgba(139, 92, 246, 0.05)',
          accent: 'rgba(16, 185, 129, 0.03)',
          highlight: 'rgba(245, 101, 101, 0.025)'
        };
      case 'high':
        return {
          primary: 'rgba(99, 102, 241, 0.25)',
          secondary: 'rgba(139, 92, 246, 0.25)',
          accent: 'rgba(16, 185, 129, 0.15)',
          highlight: 'rgba(245, 101, 101, 0.12)'
        };
      default: // medium
        return {
          primary: 'rgba(99, 102, 241, 0.15)',
          secondary: 'rgba(139, 92, 246, 0.15)',
          accent: 'rgba(16, 185, 129, 0.08)',
          highlight: 'rgba(245, 101, 101, 0.06)'
        };
    }
  };

  const colors = getIntensityStyles();

  return (
    <div 
      className={`fixed inset-0 pointer-events-none z-0 ${className}`}
      style={{
        background: interactive 
          ? `
            radial-gradient(circle at ${mousePos.x}% ${mousePos.y}%, ${colors.primary} 0%, transparent 50%),
            radial-gradient(circle at ${100 - mousePos.x}% ${100 - mousePos.y}%, ${colors.secondary} 0%, transparent 50%),
            radial-gradient(circle at 50% 50%, ${colors.accent} 0%, transparent 60%),
            radial-gradient(circle at 25% 75%, ${colors.highlight} 0%, transparent 40%)
          `
          : `
            radial-gradient(circle at 20% 20%, ${colors.primary} 0%, transparent 50%),
            radial-gradient(circle at 80% 80%, ${colors.secondary} 0%, transparent 50%),
            radial-gradient(circle at 60% 40%, ${colors.accent} 0%, transparent 60%),
            radial-gradient(circle at 40% 80%, ${colors.highlight} 0%, transparent 45%)
          `,
        backgroundSize: '100% 100%, 120% 120%, 80% 80%, 150% 150%',
        animation: interactive ? 'none' : 'backgroundShift 20s ease-in-out infinite'
      }}
    >
      {/* Floating particles layer */}
      <div 
        className="absolute inset-0"
        style={{
          backgroundImage: `
            radial-gradient(circle at 10% 60%, ${colors.primary}50 0%, transparent 30%),
            radial-gradient(circle at 90% 30%, ${colors.secondary}50 0%, transparent 30%),
            radial-gradient(circle at 30% 90%, ${colors.accent}50 0%, transparent 25%),
            radial-gradient(circle at 70% 10%, ${colors.highlight}50 0%, transparent 25%)
          `,
          backgroundSize: '150% 150%, 180% 180%, 120% 120%, 200% 200%',
          animation: 'particlesFloat 25s ease-in-out infinite reverse'
        }}
      />
      
      {/* Aurora overlay */}
      <div 
        className="absolute inset-0 opacity-30"
        style={{
          background: `
            linear-gradient(135deg, 
              transparent 0%, 
              ${colors.primary}20 25%, 
              transparent 50%, 
              ${colors.secondary}20 75%, 
              transparent 100%)
          `,
          backgroundSize: '200% 200%',
          animation: 'aurora 12s ease-in-out infinite'
        }}
      />
    </div>
  );
}