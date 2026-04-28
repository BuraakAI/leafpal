export interface DiagnosisIssue {
  name: string;
  description: string;
  solution: string;
  severity: 'low' | 'medium' | 'high';
}

export interface DiagnosisResult {
  possibleIssues: DiagnosisIssue[];
  disclaimer: string;
}

export type Symptom =
  | 'yellowing'
  | 'spots'
  | 'wilting'
  | 'dropping'
  | 'root_rot'
  | 'pests'
  | 'leggy'
  | 'pale';
