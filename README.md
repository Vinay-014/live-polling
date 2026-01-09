# Resilient Live Polling System

A real-time, resilient polling application built for the Intervue.io SDE Intern assignment. This system allows teachers to create polls and students to vote in real-time, handling connection drops and page reloads gracefully.



## Tech Stack

- **Frontend**: React (Vite), TypeScript, CSS Modules (Custom Design System).
- **Backend**: Node.js, Express, Socket.io.
- **Database**: Supabase (a postgres db)

## Features

### TeacherView

- **Create Polls**: Set questions, options, and a timer (e.g., 60s).
- **Live Dashboard**: View real-time participation updates.
- **Poll History**: Review past poll results.
- **Kick Student**: Remove disruptive students from the session.

### StudentView

- **Interactive Onboarding**: Enter name to join.
- **Live Polling**: Receive questions instantly.
- **Synchronized Timer**: Timer syncs with server; resilience against refreshes.
- **Vote & Results**: Visual feedback on selection and real-time results bar.

### Resilience

- **State Recovery**: Refreshing the page maintains the user's state (Active Poll, Timer, Vote Status).
- **Edge Cases**: Handles late joiners, kicked students, and network reconnection.

## Getting Started

### Prerequisites

- Node.js (v18+)
- SUPABASE URL and KEY

### Local Setup

1.  **Clone the Repository**

    ```bash
    git clone <repository-url>
    cd live-polling-system
    ```

2.  **Setup Backend**

    ```bash
    cd server
    npm install
    # Create .env file with DATABASE_URL="postgresql://..."
    npx prisma generate
    npm run dev
    ```

3.  **Setup Frontend**

    ```bash
    cd client
    npm install
    npm run dev
    ```


## Features

- [x] Teacher: Create Poll & History.
- [x] Student: Join, Vote, Real-time updates.
- [x] Resilience: Refresh logic & Late Joiner Sync.
- [x] UI: Figma compliance.

---
