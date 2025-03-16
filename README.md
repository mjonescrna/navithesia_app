# NavisThesia Web Portal

This web platform is designed to complement and extend the NavisThesia Flutter mobile app for nurse anesthesia education programs.

## Overview

The NavisThesia platform consists of two main components:
1. **NavisThesia Mobile App** (Flutter): For student case logging and tracking
2. **NavisThesia Web Portal** (This project): For administration, reporting, and extended functionality

## Project Structure

```
navithesia_portal/
├── backend/               # Server code
│   └── src/               # Source code
├── frontend/              # Web interfaces
│   ├── admin/             # React-based admin interface
│   └── student/           # Flutter web student interface
├── docs/                  # Documentation
├── project_linkage.md     # Documentation of app-portal integration
└── README.md              # This file
```

## Key Features

- Multi-tiered admin system (Owner, School Admin, Student)
- Enhanced reporting and analytics
- Hospital Culture Analytics (CLP)
- Messaging system (admin-student and student-student)
- Cloud-based clinical procedure database
- Student cohort management
- Clinical site management and analysis

## Technology Stack

- Backend: Node.js with Express
- Database: MongoDB
- Admin Frontend: React with Material UI
- Student Frontend: Flutter Web
- API Layer: GraphQL
- Authentication: Firebase Auth

## Integration with Mobile App

This web portal connects to the NavisThesia mobile app through a shared API. See the `project_linkage.md` file for details on how the two components work together.

## Development Status

This project is in the initial planning and setup phase.
