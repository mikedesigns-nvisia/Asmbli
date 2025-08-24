import React, { useState, useEffect } from 'react';
import { Button } from '../ui/button';
import { Card, CardContent, CardHeader, CardTitle } from '../ui/card';
import { Dialog, DialogContent, DialogDescription, DialogHeader, DialogTitle, DialogTrigger } from '../ui/dialog';
import { Input } from '../ui/input';
import { Label } from '../ui/label';
import { Textarea } from '../ui/textarea';
import { Badge } from '../ui/badge';
import { RadioGroup, RadioGroupItem } from '../ui/radio-group';
import { toast } from 'sonner';
import { 
  MessageSquare, 
  Star, 
  Bug, 
  Lightbulb, 
  Send, 
  ThumbsUp, 
  ThumbsDown,
  Smile,
  Meh,
  ChevronRight,
  X
} from 'lucide-react';
import emailjs from '@emailjs/browser';

interface FeedbackData {
  type: 'nps' | 'bug' | 'feature' | 'quick' | 'completion';
  rating?: number;
  message: string;
  email?: string;
  context: {
    step: number;
    role: string;
    tools: string[];
    timestamp: string;
    userAgent: string;
    url: string;
  };
}

interface FeedbackSystemProps {
  currentStep: number;
  wizardData: any;
  onComplete?: () => void;
}

const NPS_LABELS = {
  0: 'Very unlikely',
  1: 'Unlikely', 
  2: 'Unlikely',
  3: 'Unlikely',
  4: 'Unlikely',
  5: 'Neutral',
  6: 'Neutral',
  7: 'Likely',
  8: 'Likely',
  9: 'Very likely',
  10: 'Extremely likely'
};

export function FeedbackSystem({ currentStep, wizardData, onComplete }: FeedbackSystemProps) {
  const [isVisible, setIsVisible] = useState(false);
  const [feedbackType, setFeedbackType] = useState<'nps' | 'bug' | 'feature' | 'quick'>('quick');
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [formData, setFormData] = useState({
    rating: 8,
    message: '',
    email: '',
    category: 'general'
  });

  // Initialize EmailJS
  useEffect(() => {
    emailjs.init("YOUR_EMAILJS_PUBLIC_KEY"); // Replace with actual public key
  }, []);

  const buildFeedbackContext = (): FeedbackData['context'] => ({
    step: currentStep,
    role: wizardData.role || 'unknown',
    tools: wizardData.tools || [],
    timestamp: new Date().toISOString(),
    userAgent: navigator.userAgent,
    url: window.location.href
  });

  const sendFeedback = async (feedbackData: FeedbackData) => {
    try {
      setIsSubmitting(true);

      // Prepare email content
      const emailContent = {
        to_email: 'mikejarce@icloud.com',
        from_name: feedbackData.email || 'Anonymous User',
        feedback_type: feedbackData.type.toUpperCase(),
        rating: feedbackData.rating || 'N/A',
        message: feedbackData.message,
        user_context: JSON.stringify(feedbackData.context, null, 2),
        subject: `Agent Builder Feedback - ${feedbackData.type.toUpperCase()}`,
        reply_to: feedbackData.email || 'noreply@agentbuilder.com'
      };

      // Send email using EmailJS
      const result = await emailjs.send(
        'YOUR_SERVICE_ID', // Replace with actual service ID
        'YOUR_TEMPLATE_ID', // Replace with actual template ID
        emailContent
      );

      if (result.status === 200) {
        toast.success('Thank you! Your feedback has been sent successfully.');
        setIsVisible(false);
        resetForm();
        if (onComplete) onComplete();
        
        // Track feedback submission locally
        const feedbackHistory = JSON.parse(localStorage.getItem('feedback_history') || '[]');
        feedbackHistory.push({
          ...feedbackData,
          submitted: new Date().toISOString()
        });
        localStorage.setItem('feedback_history', JSON.stringify(feedbackHistory));
      }
    } catch (error) {
      // Console output removed for production
      toast.error('Failed to send feedback. Please try again or contact support directly.');
    } finally {
      setIsSubmitting(false);
    }
  };

  const resetForm = () => {
    setFormData({
      rating: 8,
      message: '',
      email: '',
      category: 'general'
    });
    setFeedbackType('quick');
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    
    if (!formData.message.trim()) {
      toast.error('Please provide some feedback before submitting.');
      return;
    }

    const feedbackData: FeedbackData = {
      type: feedbackType,
      rating: feedbackType === 'nps' ? formData.rating : undefined,
      message: formData.message,
      email: formData.email,
      context: buildFeedbackContext()
    };

    sendFeedback(feedbackData);
  };

  const handleQuickFeedback = (sentiment: 'positive' | 'negative', message: string) => {
    const feedbackData: FeedbackData = {
      type: 'quick',
      message: `Quick feedback: ${sentiment} - ${message}`,
      context: buildFeedbackContext()
    };
    
    sendFeedback(feedbackData);
  };

  const NPSRating = () => (
    <div className="space-y-4">
      <div>
        <Label className="text-sm font-medium">
          How likely are you to recommend Agent Builder to a colleague? (0-10)
        </Label>
        <div className="flex items-center justify-between mt-2">
          <span className="text-xs text-muted-foreground">Not likely</span>
          <span className="text-xs text-muted-foreground">Very likely</span>
        </div>
      </div>
      
      <div className="flex gap-2 flex-wrap justify-center">
        {[...Array(11)].map((_, i) => (
          <Button
            key={i}
            variant={formData.rating === i ? "default" : "outline"}
            size="sm"
            className="w-10 h-10 p-0"
            onClick={() => setFormData({ ...formData, rating: i })}
          >
            {i}
          </Button>
        ))}
      </div>
      
      <div className="text-center">
        <Badge variant="outline" className="text-xs">
          {NPS_LABELS[formData.rating as keyof typeof NPS_LABELS]}
        </Badge>
      </div>
    </div>
  );

  const BugReportForm = () => (
    <div className="space-y-4">
      <div>
        <Label htmlFor="category">Issue Category</Label>
        <RadioGroup
          value={formData.category}
          onValueChange={(value) => setFormData({ ...formData, category: value })}
          className="flex flex-wrap gap-4 mt-2"
        >
          <div className="flex items-center space-x-2">
            <RadioGroupItem value="ui" id="ui" />
            <Label htmlFor="ui" className="text-sm">UI/UX Issue</Label>
          </div>
          <div className="flex items-center space-x-2">
            <RadioGroupItem value="functionality" id="functionality" />
            <Label htmlFor="functionality" className="text-sm">Functionality</Label>
          </div>
          <div className="flex items-center space-x-2">
            <RadioGroupItem value="performance" id="performance" />
            <Label htmlFor="performance" className="text-sm">Performance</Label>
          </div>
          <div className="flex items-center space-x-2">
            <RadioGroupItem value="other" id="other" />
            <Label htmlFor="other" className="text-sm">Other</Label>
          </div>
        </RadioGroup>
      </div>
    </div>
  );

  // Quick feedback floating widget
  const QuickFeedbackWidget = () => {
    const [showQuickOptions, setShowQuickOptions] = useState(false);

    return (
      <div className="fixed bottom-20 right-6 z-30">
        {showQuickOptions && (
          <Card className="mb-4 w-72 shadow-lg border-primary/20 bg-background/95 backdrop-blur-sm">
            <CardHeader className="pb-3">
              <div className="flex items-center justify-between">
                <CardTitle className="text-sm">Quick Feedback</CardTitle>
                <Button
                  variant="ghost"
                  size="sm"
                  onClick={() => setShowQuickOptions(false)}
                  className="h-6 w-6 p-0"
                >
                  <X className="w-4 h-4" />
                </Button>
              </div>
            </CardHeader>
            <CardContent className="space-y-3">
              <div className="grid grid-cols-2 gap-2">
                <Button
                  variant="outline"
                  size="sm"
                  onClick={() => handleQuickFeedback('positive', 'Easy to use')}
                  className="flex items-center gap-2 text-primary border-primary/20 hover:bg-primary/5"
                >
                  <ThumbsUp className="w-4 h-4" />
                  Easy to use
                </Button>
                <Button
                  variant="outline"
                  size="sm"
                  onClick={() => handleQuickFeedback('positive', 'Very helpful')}
                  className="flex items-center gap-2 text-primary border-primary/20 hover:bg-primary/5"
                >
                  <Smile className="w-4 h-4" />
                  Very helpful
                </Button>
                <Button
                  variant="outline"
                  size="sm"
                  onClick={() => handleQuickFeedback('negative', 'Confusing')}
                  className="flex items-center gap-2 text-muted-foreground border-border hover:bg-muted"
                >
                  <Meh className="w-4 h-4" />
                  Confusing
                </Button>
                <Button
                  variant="outline"
                  size="sm"
                  onClick={() => handleQuickFeedback('negative', 'Not working')}
                  className="flex items-center gap-2 text-muted-foreground border-border hover:bg-muted"
                >
                  <ThumbsDown className="w-4 h-4" />
                  Not working
                </Button>
              </div>
              <Button
                variant="ghost"
                size="sm"
                onClick={() => {
                  setShowQuickOptions(false);
                  setIsVisible(true);
                  setFeedbackType('quick');
                }}
                className="w-full flex items-center gap-2"
              >
                <MessageSquare className="w-4 h-4" />
                Write detailed feedback
                <ChevronRight className="w-4 h-4" />
              </Button>
            </CardContent>
          </Card>
        )}

        <Button
          onClick={() => setShowQuickOptions(!showQuickOptions)}
          className="shadow-lg bg-primary hover:bg-primary/90"
          size="sm"
        >
          <MessageSquare className="w-4 h-4 mr-2" />
          Feedback
        </Button>
      </div>
    );
  };

  return (
    <>
      {/* Quick Feedback Widget */}
      <QuickFeedbackWidget />

      {/* Main Feedback Dialog */}
      <Dialog open={isVisible} onOpenChange={setIsVisible}>
        
        <DialogContent className="sm:max-w-md z-40">
          <DialogHeader>
            <DialogTitle className="flex items-center gap-2">
              {feedbackType === 'nps' && <Star className="w-5 h-5 text-primary" />}
              {feedbackType === 'bug' && <Bug className="w-5 h-5 text-primary" />}
              {feedbackType === 'feature' && <Lightbulb className="w-5 h-5 text-primary" />}
              {feedbackType === 'quick' && <MessageSquare className="w-5 h-5 text-primary" />}
              
              {feedbackType === 'nps' && 'Rate Your Experience'}
              {feedbackType === 'bug' && 'Report an Issue'}
              {feedbackType === 'feature' && 'Suggest a Feature'}
              {feedbackType === 'quick' && 'Share Feedback'}
            </DialogTitle>
            <DialogDescription>
              Your feedback helps us improve Agent Builder for everyone.
            </DialogDescription>
          </DialogHeader>

          <form onSubmit={handleSubmit} className="space-y-4">
            {/* Feedback Type Selector */}
            <div className="flex gap-2 p-1 bg-muted rounded-lg">
              <Button
                type="button"
                variant={feedbackType === 'quick' ? 'default' : 'ghost'}
                size="sm"
                onClick={() => setFeedbackType('quick')}
                className="flex-1"
              >
                <MessageSquare className="w-4 h-4 mr-1" />
                General
              </Button>
              <Button
                type="button"
                variant={feedbackType === 'bug' ? 'default' : 'ghost'}
                size="sm"
                onClick={() => setFeedbackType('bug')}
                className="flex-1"
              >
                <Bug className="w-4 h-4 mr-1" />
                Bug
              </Button>
              <Button
                type="button"
                variant={feedbackType === 'feature' ? 'default' : 'ghost'}
                size="sm"
                onClick={() => setFeedbackType('feature')}
                className="flex-1"
              >
                <Lightbulb className="w-4 h-4 mr-1" />
                Feature
              </Button>
              <Button
                type="button"
                variant={feedbackType === 'nps' ? 'default' : 'ghost'}
                size="sm"
                onClick={() => setFeedbackType('nps')}
                className="flex-1"
              >
                <Star className="w-4 h-4 mr-1" />
                Rate
              </Button>
            </div>

            {/* NPS Rating */}
            {feedbackType === 'nps' && <NPSRating />}

            {/* Bug Report Form */}
            {feedbackType === 'bug' && <BugReportForm />}

            {/* Message Input */}
            <div>
              <Label htmlFor="message">
                {feedbackType === 'bug' && 'Describe the issue'}
                {feedbackType === 'feature' && 'Describe your feature idea'}
                {feedbackType === 'nps' && 'Tell us more about your rating (optional)'}
                {feedbackType === 'quick' && 'Your feedback'}
              </Label>
              <Textarea
                id="message"
                placeholder={
                  feedbackType === 'bug' ? 'What happened? What did you expect to happen?' :
                  feedbackType === 'feature' ? 'What feature would you like to see?' :
                  feedbackType === 'nps' ? 'What influenced your rating?' :
                  'How can we improve your experience?'
                }
                value={formData.message}
                onChange={(e) => setFormData({ ...formData, message: e.target.value })}
                className="min-h-[100px]"
                required
              />
            </div>

            {/* Email Input */}
            <div>
              <Label htmlFor="email">Email (optional)</Label>
              <Input
                id="email"
                type="email"
                placeholder="your@email.com"
                value={formData.email}
                onChange={(e) => setFormData({ ...formData, email: e.target.value })}
              />
              <p className="text-xs text-muted-foreground mt-1">
                We'll only use this to follow up on your feedback if needed.
              </p>
            </div>

            {/* Submit Buttons */}
            <div className="flex gap-2 pt-4">
              <Button
                type="button"
                variant="outline"
                onClick={() => setIsVisible(false)}
                className="flex-1"
              >
                Cancel
              </Button>
              <Button
                type="submit"
                disabled={isSubmitting}
                className="flex-1 flex items-center gap-2"
              >
                {isSubmitting ? (
                  <>
                    <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-white" />
                    Sending...
                  </>
                ) : (
                  <>
                    <Send className="w-4 h-4" />
                    Send Feedback
                  </>
                )}
              </Button>
            </div>
          </form>
        </DialogContent>
      </Dialog>
    </>
  );
}

// Hook for completion survey
export function useCompletionSurvey() {
  const [showSurvey, setShowSurvey] = useState(false);

  const triggerSurvey = () => {
    // Check if user has already completed survey recently
    const lastSurvey = localStorage.getItem('last_completion_survey');
    const now = new Date().getTime();
    const oneWeek = 7 * 24 * 60 * 60 * 1000;

    if (!lastSurvey || now - parseInt(lastSurvey) > oneWeek) {
      setTimeout(() => setShowSurvey(true), 2000);
    }
  };

  const completeSurvey = () => {
    setShowSurvey(false);
    localStorage.setItem('last_completion_survey', new Date().getTime().toString());
  };

  return {
    showSurvey,
    triggerSurvey,
    completeSurvey,
    dismissSurvey: () => setShowSurvey(false)
  };
}