/**
 * OpenAPI 3.0 Documentation Specification for Performance Evaluation Tool API
 */

const openApiSpec = {
  openapi: '3.0.0',
  info: {
    title: 'Performance Evaluation Tool API',
    version: '1.0.0',
    description: 'Multi-Tenant Performance Evaluation System API supporting HR compliance tracking, direct manager evaluations, and employee score trend analytics.'
  },
  servers: [
    {
      url: 'http://localhost:5000',
      description: 'Development Server'
    }
  ],
  components: {
    securitySchemes: {
      BearerAuth: {
        type: 'http',
        scheme: 'bearer',
        bearerFormat: 'JWT',
        description: 'Enter your JWT token in the format: Bearer <token>'
      }
    },
    schemas: {
      StandardSuccessResponse: {
        type: 'object',
        properties: {
          success: { type: 'boolean', example: true },
          message: { type: 'string', example: 'Operation completed successfully' },
          data: { type: 'object' }
        }
      },
      StandardErrorResponse: {
        type: 'object',
        properties: {
          success: { type: 'boolean', example: false },
          message: { type: 'string', example: 'Error message description' },
          data: { type: 'object', nullable: true, example: null }
        }
      },
      LoginRequest: {
        type: 'object',
        required: ['email', 'password'],
        properties: {
          email: { type: 'string', example: 'priya@ashoka.com' },
          password: { type: 'string', example: 'Password123!' }
        }
      },
      EvaluationScoreInput: {
        type: 'object',
        required: ['parameterId', 'score', 'comment'],
        properties: {
          parameterId: { type: 'string', format: 'uuid', example: '123e4567-e89b-12d3-a456-426614174000' },
          score: { type: 'integer', minimum: 1, maximum: 5, example: 4 },
          comment: { type: 'string', example: 'Consistently delivers high quality output.' }
        }
      },
      CreateEvaluationPayload: {
        type: 'object',
        required: ['cycleId', 'employeeId', 'scores'],
        properties: {
          cycleId: { type: 'string', format: 'uuid' },
          employeeId: { type: 'string', format: 'uuid' },
          summaryComment: { type: 'string', example: 'Overall strong monthly performance.' },
          submit: { type: 'boolean', default: false },
          scores: {
            type: 'array',
            items: { $ref: '#/components/schemas/EvaluationScoreInput' },
            minItems: 5,
            maxItems: 5
          }
        }
      }
    }
  },
  security: [
    { BearerAuth: [] }
  ],
  paths: {
    '/health': {
      get: {
        summary: 'Root Server Information',
        tags: ['Health'],
        security: [],
        responses: {
          200: { description: 'API Server Information' }
        }
      }
    },
    '/api/health': {
      get: {
        summary: 'Application Health Check',
        tags: ['Health'],
        security: [],
        responses: {
          200: { description: 'Health Status' }
        }
      }
    },
    '/api/auth/login': {
      post: {
        summary: 'User Login',
        tags: ['Authentication'],
        security: [],
        requestBody: {
          required: true,
          content: {
            'application/json': {
              schema: { $ref: '#/components/schemas/LoginRequest' }
            }
          }
        },
        responses: {
          200: { description: 'Authenticated successfully, returns JWT token' },
          401: { description: 'Invalid credentials' }
        }
      }
    },
    '/api/auth/me': {
      get: {
        summary: 'Get Authenticated User Context',
        tags: ['Authentication'],
        responses: {
          200: { description: 'Current authenticated user details' },
          401: { description: 'Unauthorized' }
        }
      }
    },
    '/api/auth/logout': {
      post: {
        summary: 'Stateless User Logout',
        tags: ['Authentication'],
        responses: {
          200: { description: 'Logged out successfully' }
        }
      }
    },
    '/api/employees/profile': {
      get: {
        summary: 'Get Logged-in Employee Profile',
        tags: ['Employee'],
        responses: {
          200: { description: 'Employee Profile' }
        }
      }
    },
    '/api/employees/evaluations/current': {
      get: {
        summary: 'Get Current Cycle Evaluation',
        tags: ['Employee'],
        responses: {
          200: { description: 'Current active cycle evaluation' }
        }
      }
    },
    '/api/employees/evaluations/history': {
      get: {
        summary: 'Get Complete Evaluation Timeline History',
        tags: ['Employee'],
        responses: {
          200: { description: 'Historical submitted reviews timeline' }
        }
      }
    },
    '/api/employees/evaluations/trends': {
      get: {
        summary: 'Get Parameter Score Trends',
        tags: ['Employee'],
        responses: {
          200: { description: 'Score trends grouped by 5 fixed parameters' }
        }
      }
    },
    '/api/managers/reports': {
      get: {
        summary: 'Get Direct Reports Roster',
        tags: ['Manager'],
        responses: {
          200: { description: 'List of assigned direct reports' }
        }
      }
    },
    '/api/managers/team-status': {
      get: {
        summary: 'Get Team Evaluation Progress Status',
        tags: ['Manager'],
        responses: {
          200: { description: 'Submission progress for direct reports' }
        }
      }
    },
    '/api/managers/evaluations': {
      post: {
        summary: 'Create or Submit Monthly Evaluation',
        tags: ['Manager'],
        requestBody: {
          required: true,
          content: {
            'application/json': {
              schema: { $ref: '#/components/schemas/CreateEvaluationPayload' }
            }
          }
        },
        responses: {
          201: { description: 'Evaluation created or submitted successfully' },
          400: { description: 'Validation failure' },
          409: { description: 'Duplicate submission conflict' }
        }
      }
    },
    '/api/managers/evaluations/{id}': {
      put: {
        summary: 'Update Draft Evaluation',
        tags: ['Manager'],
        parameters: [
          { name: 'id', in: 'path', required: true, schema: { type: 'string', format: 'uuid' } }
        ],
        responses: {
          200: { description: 'Evaluation updated' },
          403: { description: 'Cannot edit finalized evaluation' }
        }
      }
    },
    '/api/managers/evaluations/{id}/submit': {
      post: {
        summary: 'Finalize & Submit Draft Evaluation',
        tags: ['Manager'],
        parameters: [
          { name: 'id', in: 'path', required: true, schema: { type: 'string', format: 'uuid' } }
        ],
        responses: {
          200: { description: 'Evaluation finalized and locked' }
        }
      }
    },
    '/api/hr/dashboard': {
      get: {
        summary: 'Get HR Compliance Metrics Dashboard',
        tags: ['HR'],
        parameters: [
          { name: 'cycleId', in: 'query', required: false, schema: { type: 'string', format: 'uuid' } }
        ],
        responses: {
          200: { description: 'HR Compliance Metrics and manager breakdown' }
        }
      }
    },
    '/api/hr/managers': {
      get: {
        summary: 'Get Manager Submissions Breakdown Table',
        tags: ['HR'],
        responses: {
          200: { description: 'List of managers and submission progress' }
        }
      }
    },
    '/api/hr/submissions/pending': {
      get: {
        summary: 'Get Pending Manager Submissions',
        tags: ['HR'],
        responses: {
          200: { description: 'Managers with incomplete reviews' }
        }
      }
    },
    '/api/hr/submissions/completed': {
      get: {
        summary: 'Get Completed Manager Submissions',
        tags: ['HR'],
        responses: {
          200: { description: 'Compliant managers' }
        }
      }
    },
    '/api/evaluations/{id}': {
      get: {
        summary: 'Get Evaluation Details by ID',
        tags: ['Evaluation'],
        parameters: [
          { name: 'id', in: 'path', required: true, schema: { type: 'string', format: 'uuid' } }
        ],
        responses: {
          200: { description: 'Full evaluation details with 5 parameter scores' }
        }
      }
    }
  }
};

module.exports = openApiSpec;
