# Infinite Descent Prototype

Infinite Descent is a fast-paced, space-themed arcade game developed with **Godot 4.6**. The player controls an astronaut trapped in the gravitational pull of a central black hole, dodging meteors and fighting through various phases inspired by the 42 School ecosystem.

## 🚀 Features

- **Dynamic Orbit Mechanics**: Experience a unique movement system where you must manage your distance from a central black hole while dodging obstacles.
- **Combat System**: 
  - **Dash**: Quick bursts of speed to escape danger.
  - **Attack**: Use sword projectiles to clear your path.
  - **Shield**: Protect yourself from incoming meteors (requires energy).
- **Multi-Phase Gameplay**:
  - **Phase 1**: Classic space survival.
  - **Phase 2 (Pedago Phase)**: The environment shifts into a Matrix-style digital realm. Watch out for the "BERKAY CLUSTERDE" alarm!
- **42 Intra Integration**:
  - **OAuth2 Login**: Sign in using your 42 account.
  - **Stats**: Fetches your 42 profile and logtime data.
- **Leaderboard**: Compete with other players via a **Supabase**-powered backend.
- **Polished VFX**: High-quality particle systems, shaders, and a custom "Matrix Rain" effect.

## 🛠️ Tech Stack

- **Game Engine**: [Godot 4.6](https://godotengine.org/) (Forward Plus / GL Compatibility)
- **Language**: GDScript
- **Backend**: [Supabase](https://supabase.com/) (Database & Edge Functions)
  - **Secure Auth**: Uses Supabase Edge Functions to safely handle 42 API token exchange and proxy sensitive requests.
- **Authentication**: 42 API (OAuth2)
- **Deployment**: Web-ready with JavaScript bridge for OAuth callbacks.

## 🕹️ Controls

- **WASD**: Movement
- **Space**: Dash
- **Left Click**: Attack
- **Right Click / K**: Shield
- **ESC**: Quit (Desktop)

## 📦 Setup & Installation

1.  **Clone the repository**:
    ```bash
    git clone https://github.com/hudayiarici/CatTheJam.git
    cd CatTheJam/godot_prototype
    ```
2.  **Open in Godot**: Launch Godot 4.6 and import `project.godot`.
3.  **Supabase Configuration**:
    - The project uses a Supabase backend. Configuration can be found in `scripts/Api42.gd`.
    - Database schema is provided in `supabase_setup.sql`.
4.  **42 API**:
    - You will need a 42 API Application to use the login feature. Update the `CLIENT_ID` and `REDIRECT_URI` in `scripts/Api42.gd` if necessary.

## 📝 License

This project is part of a game jam/prototype series. Feel free to explore and learn!

---
*Created with ❤️ by harici and melmbaz.*
