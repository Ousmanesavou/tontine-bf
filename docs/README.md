# Tontine BF — Application de gestion de tontines

Application mobile et backend pour la gestion digitale des tontines au Burkina Faso.
Conçue pour fonctionner en ville comme en zone rurale, pour les smartphones comme pour les téléphones basiques.

---

## Stack technique

| Couche | Technologie | Pourquoi |
|--------|-------------|----------|
| Mobile | Flutter | Rapide, fonctionne sur appareils bas de gamme |
| Backend | Node.js + Express | Rapide, parfait pour transactions temps réel |
| IA Vocale | Python + FastAPI | Meilleur pour le traitement vocal et NLP |
| Base de données | PostgreSQL | Fiabilité maximale pour les données financières |
| Cache | Redis | Sessions et comptes à rebours temps réel |
| Hors-ligne | SQLite local | Fonctionne sans réseau |
| SMS/USSD/Vocal | Africa's Talking | Présent au Burkina, couvre les téléphones basiques |
| WhatsApp | WhatsApp Business API | Notifications au groupe |
| Mobile Money | Orange Money + Moov Money | Paiements intégrés |
| Cloud | Render → AWS | Démarrage rapide, migration facile |

---

## Structure du projet

```
tontine-app/
├── backend/                    # Serveur Node.js
│   ├── src/
│   │   ├── index.js           # Point d'entrée
│   │   ├── routes/            # Routes API
│   │   │   ├── auth.js        # Inscription / Connexion
│   │   │   ├── tontines.js    # CRUD tontines + membres
│   │   │   ├── cotisations.js # Cotisations routes
│   │   │   ├── paiements.js   # Orange Money + Moov Money
│   │   │   ├── catalogue.js   # Produits catalogue
│   │   │   ├── notifications.js
│   │   │   └── ussd.js        # Interface USSD téléphones basiques
│   │   ├── controllers/       # Logique métier
│   │   ├── services/
│   │   │   ├── notificationService.js  # SMS + WhatsApp + Push + Vocal
│   │   │   ├── paiementService.js      # Orange Money + Moov Money
│   │   │   ├── ussdService.js          # Menus USSD multilingues
│   │   │   └── cronJobs.js             # Rappels + rapports automatiques
│   │   ├── middleware/
│   │   │   ├── auth.js        # JWT authentification
│   │   │   └── validation.js  # Validation données Joi
│   │   └── utils/
│   │       └── logger.js      # Winston logger
│   └── config/
│       ├── database.js        # PostgreSQL + création tables
│       └── redis.js           # Cache Redis
├── mobile/                    # Application Flutter (à développer)
└── docs/                      # Documentation

```

---

## Fonctionnalités implémentées

### Authentification
- [x] Inscription avec numéro Burkina Faso (validation format)
- [x] Connexion par code PIN 4 chiffres
- [x] JWT tokens 30 jours
- [x] Choix de langue à l'inscription (mooré / dioula / français)

### Tontines
- [x] Création tontine : argent liquide, objet, caisse fixe, événementielle
- [x] Périodicité flexible : quotidien, 2 jours, hebdo, 2 semaines, mensuel, personnalisé
- [x] Génération automatique des cotisations sur toute la durée
- [x] Calcul automatique de la date de fin
- [x] Invitation membres par téléphone (SMS si non inscrit)
- [x] Gestion rotation : tirage au sort / manuel / par besoin
- [x] Statistiques groupe : taux paiement, montants, scores
- [x] Rapport financier complet
- [x] Emprunts avec vote du groupe

### Paiements
- [x] Intégration Orange Money Burkina Faso
- [x] Intégration Moov Money Burkina Faso
- [x] Dépôt physique pour membres sans mobile money
- [x] Webhooks de confirmation automatique
- [x] Score de fiabilité mis à jour à chaque transaction

### Notifications multilingues (FR / Mooré / Dioula)
- [x] SMS via Africa's Talking
- [x] Messages vocaux automatiques
- [x] Notifications WhatsApp
- [x] Push notifications (mobile)
- [x] Rappels automatiques J-2 et J-1
- [x] Marquage automatique des retards
- [x] Rapports mensuels automatiques

### USSD (téléphones basiques)
- [x] Menu USSD en 3 langues
- [x] Voir mes tontines
- [x] Vérifier mon solde / cotisations
- [x] Initier un paiement
- [x] Voir son tour dans la rotation

---

## Installation et démarrage

```bash
# Cloner le projet
git clone [url]
cd tontine-app/backend

# Installer les dépendances
npm install

# Configurer les variables d'environnement
cp .env.example .env
# Éditer .env avec vos clés API

# Démarrer en développement
npm run dev

# Démarrer en production
npm start
```

### Prérequis
- Node.js 18+
- PostgreSQL 14+
- Redis 7+
- Compte Africa's Talking (SMS/USSD)
- Compte Orange Money Burkina (API marchands)
- Compte Moov Money Burkina (API marchands)
- Compte WhatsApp Business API (optionnel)

---

## API Endpoints principaux

### Auth
```
POST /api/auth/inscription
POST /api/auth/connexion
```

### Tontines
```
GET    /api/tontines              # Mes tontines
POST   /api/tontines              # Créer une tontine
GET    /api/tontines/:id          # Détail tontine
GET    /api/tontines/:id/membres  # Liste membres
POST   /api/tontines/:id/membres/inviter
GET    /api/tontines/:id/cotisations
GET    /api/tontines/:id/statistiques
GET    /api/tontines/:id/rapport
POST   /api/tontines/:id/emprunts
```

### Paiements
```
GET  /api/cotisations/mes-cotisations
POST /api/cotisations/payer
POST /api/cotisations/depot-physique
POST /api/cotisations/webhook/orange
POST /api/cotisations/webhook/moov
```

### USSD
```
POST /ussd    # Endpoint Africa's Talking
```

---

## Roadmap

### Phase 1 - MVP (Mois 1-3) ✅ En cours
- [x] Backend Node.js complet
- [x] Base de données PostgreSQL
- [x] Authentification JWT
- [x] Gestion tontines argent liquide
- [x] Intégration Orange Money + Moov Money
- [x] SMS + WhatsApp notifications
- [x] Interface USSD
- [ ] Application Flutter (écrans principaux)
- [ ] Tests avec 5 groupes pilotes Ouaga

### Phase 2 - Catalogue (Mois 4-6)
- [ ] Catalogue produits avec photos/vidéos
- [ ] Gestion fournisseurs partenaires
- [ ] Tontine d'objets complète
- [ ] Intégration livraison
- [ ] 50 groupes actifs

### Phase 3 - Scale (Mois 7-12)
- [ ] Assistant IA vocal en mooré et dioula
- [ ] Score de crédit basé sur historique tontine
- [ ] Dashboard web pour responsables
- [ ] Extension Bobo-Dioulasso
- [ ] 500+ groupes actifs

### Phase 4 - Expansion (Année 2)
- [ ] Mali, Niger, Côte d'Ivoire
- [ ] Partenariats bancaires et microfinance
- [ ] API publique pour partenaires

---

## Modèle économique

| Source | Mécanisme | Estimation |
|--------|-----------|------------|
| Commission Mobile Money | 0.5% par transaction | Principal |
| Commission fournisseurs catalogue | 3-5% par vente | Fort |
| Abonnement groupes premium | 1 000F/mois | Récurrent |
| Score de crédit | Données anonymisées → microfinance | Phase 3 |

---

## Contact & Contribution

Projet développé pour le Burkina Faso.
Langues supportées : Français · Mooré · Dioula
