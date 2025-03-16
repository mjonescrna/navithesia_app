# NavisThesia Project Linkage

This document describes the relationship and integration between the NavisThesia mobile app and the web portal.

## Project Structure

The NavisThesia platform consists of two separate but connected projects:

1. **NavisThesia Mobile App**
   - Location: `C:\Users\mjone\navithesia_beta`
   - Technology: Flutter
   - Primary Users: Nurse anesthesia students (SRNAs/RRNAs/NARs)

2. **NavisThesia Web Portal**
   - Location: `C:\Users\mjone\navithesia_portal`
   - Technology: Node.js (backend), React & Flutter Web (frontend)
   - Primary Users: School administrators, program directors, students (web access)

## Integration Points

### 1. Data Synchronization

The mobile app and web portal share data through a RESTful API:

- **Student Case Logs**: Created on the mobile app, viewable on the web
- **Clinical Requirements**: Tracked on the app, reported on the web
- **User Profiles**: Managed centrally, accessible on both platforms
- **Messaging**: Accessible from both platforms with appropriate permissions

### 2. API Structure

The web portal will expose APIs for the mobile app to:
- Authenticate users
- Sync case logs and clinical hours
- Retrieve procedure database updates
- Send/receive messages
- Update profile information

### 3. Authentication Flow

- Shared authentication system (Firebase Auth or similar)
- Single sign-on between platforms
- Role-based permissions controlling access levels

### 4. Database Architecture

- Cloud-based clinical procedure database (MongoDB)
- Hospital culture analytics database
- User and messaging database
- Reporting data warehouse

## Development Guidelines

1. **No Direct Coupling**: Changes to one platform should not break the other
2. **API-First Approach**: Define stable API contracts before implementation
3. **Versioned APIs**: Support backward compatibility for mobile app
4. **Feature Parity**: Core features available on both platforms where appropriate

## Version Compatibility

This document will be updated to track version compatibility between the mobile app and web portal as development progresses. 