export interface RegisterBody {
  email: string;
  password: string;
  name?: string;
}

export interface LoginBody {
  email: string;
  password: string;
}

export interface AuthResponse {
  token: string;
  user: {
    id: string;
    email: string;
    name: string | null;
  };
  trial: {
    isTrialAccepted: boolean;
    isPremium: boolean;
    trialDaysLeft: number;
    trialExpired: boolean;
    scansRemainingToday: number;
    canScan: boolean;
  };
}
