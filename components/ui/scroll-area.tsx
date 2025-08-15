"use client";

import * as React from "react";
import { cn } from "./utils";

interface ScrollAreaProps extends React.HTMLAttributes<HTMLDivElement> {
  children: React.ReactNode;
}

function ScrollArea({ className, children, ...props }: ScrollAreaProps) {
  return (
    <div
      className={cn("relative overflow-auto scrollbar-thin scrollbar-thumb-border scrollbar-track-background", className)}
      {...props}
    >
      {children}
    </div>
  );
}

interface ScrollBarProps extends React.HTMLAttributes<HTMLDivElement> {
  orientation?: "vertical" | "horizontal";
}

function ScrollBar({}: ScrollBarProps) {
  // Simple implementation - the scrollbar styling is handled by CSS classes above
  return null;
}

export { ScrollArea, ScrollBar };