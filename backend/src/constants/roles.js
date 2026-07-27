/**
 * System Role Constants
 */
const ROLES = {
  HR: 'HR',
  MANAGER: 'MANAGER',
  EMPLOYEE: 'EMPLOYEE'
};

/**
 * Fixed 5 Performance Evaluation Parameter Codes
 */
const EVALUATION_PARAMETERS = [
  { code: 'WORK_QUALITY', name: 'Quality of Work', displayOrder: 1 },
  { code: 'PRODUCTIVITY', name: 'Productivity & Efficiency', displayOrder: 2 },
  { code: 'COMMUNICATION', name: 'Communication & Teamwork', displayOrder: 3 },
  { code: 'PROBLEM_SOLVING', name: 'Problem Solving & Initiative', displayOrder: 4 },
  { code: 'RELIABILITY', name: 'Ownership & Reliability', displayOrder: 5 }
];

module.exports = {
  ROLES,
  EVALUATION_PARAMETERS
};
