const { Pool } = require('pg');
const logger = require('../src/utils/logger');

const pool = new Pool(
  process.env.DATABASE_URL
    ? {
        connectionString: process.env.DATABASE_URL,
        ssl: { rejectUnauthorized: false },
      }
    : {
        host: process.env.DB_HOST,
        port: process.env.DB_PORT,
        database: process.env.DB_NAME,
        user: process.env.DB_USER,
        password: process.env.DB_PASSWORD,
        max: 20,
        idleTimeoutMillis: 30000,
        connectionTimeoutMillis: 2000,
      }
);

async function connectDB() {
  try {
    const client = await pool.connect();
    logger.info('PostgreSQL connecté avec succès');
    await createTables(client);
    client.release();
  } catch (err) {
    logger.error('Erreur connexion PostgreSQL:', err);
    process.exit(1);
  }
}

async function createTables(client) {
  // Étape 1 — Créer les tables
  await client.query(`
    CREATE TABLE IF NOT EXISTS utilisateurs (
      id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      nom VARCHAR(100) NOT NULL,
      prenom VARCHAR(100) NOT NULL,
      telephone VARCHAR(20) UNIQUE NOT NULL,
      code_pin VARCHAR(255) NOT NULL,
      langue VARCHAR(10) DEFAULT 'fr',
      type_acces VARCHAR(20) DEFAULT 'smartphone',
      orange_money_numero VARCHAR(20),
      moov_money_numero VARCHAR(20),
      score_fiabilite INTEGER DEFAULT 100,
      est_actif BOOLEAN DEFAULT true,
      created_at TIMESTAMP DEFAULT NOW(),
      updated_at TIMESTAMP DEFAULT NOW()
    );

    CREATE TABLE IF NOT EXISTS tontines (
      id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      nom VARCHAR(200) NOT NULL,
      type VARCHAR(30) NOT NULL,
      description TEXT,
      montant_cotisation DECIMAL(12,2) NOT NULL,
      periodicite VARCHAR(20) NOT NULL,
      periodicite_jours INTEGER DEFAULT 1,
      nombre_membres INTEGER NOT NULL,
      date_debut DATE NOT NULL,
      date_fin DATE,
      statut VARCHAR(20) DEFAULT 'active',
      ordre_rotation VARCHAR(20) DEFAULT 'tirage_sort',
      responsable_id UUID REFERENCES utilisateurs(id),
      produit_catalogue_id UUID,
      created_at TIMESTAMP DEFAULT NOW(),
      updated_at TIMESTAMP DEFAULT NOW()
    );

    CREATE TABLE IF NOT EXISTS membres_tontine (
      id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      tontine_id UUID REFERENCES tontines(id) ON DELETE CASCADE,
      utilisateur_id UUID REFERENCES utilisateurs(id),
      position_rotation INTEGER NOT NULL,
      a_recu BOOLEAN DEFAULT false,
      date_reception DATE,
      est_actif BOOLEAN DEFAULT true,
      joined_at TIMESTAMP DEFAULT NOW(),
      UNIQUE(tontine_id, utilisateur_id)
    );

    CREATE TABLE IF NOT EXISTS cotisations (
      id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      tontine_id UUID REFERENCES tontines(id),
      membre_id UUID REFERENCES utilisateurs(id),
      montant DECIMAL(12,2) NOT NULL,
      periode_numero INTEGER NOT NULL,
      date_echeance DATE NOT NULL,
      date_paiement TIMESTAMP,
      statut VARCHAR(20) DEFAULT 'en_attente',
      methode_paiement VARCHAR(30),
      reference_transaction VARCHAR(100),
      created_at TIMESTAMP DEFAULT NOW()
    );

    CREATE TABLE IF NOT EXISTS catalogue_produits (
      id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      nom VARCHAR(200) NOT NULL,
      categorie VARCHAR(50) NOT NULL,
      description TEXT,
      prix DECIMAL(12,2) NOT NULL,
      photos JSONB DEFAULT '[]',
      video_url VARCHAR(500),
      fournisseur_nom VARCHAR(200),
      fournisseur_contact VARCHAR(20),
      livraison_disponible BOOLEAN DEFAULT false,
      est_actif BOOLEAN DEFAULT true,
      created_at TIMESTAMP DEFAULT NOW()
    );

    CREATE TABLE IF NOT EXISTS fournisseurs (
      id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      nom VARCHAR(200) NOT NULL,
      categorie VARCHAR(50),
      telephone VARCHAR(20),
      adresse TEXT,
      livraison_disponible BOOLEAN DEFAULT false,
      est_actif BOOLEAN DEFAULT true,
      created_at TIMESTAMP DEFAULT NOW()
    );

    CREATE TABLE IF NOT EXISTS emprunts (
      id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      tontine_id UUID REFERENCES tontines(id),
      emprunteur_id UUID REFERENCES utilisateurs(id),
      montant DECIMAL(12,2) NOT NULL,
      taux_interet DECIMAL(5,2) DEFAULT 0,
      date_emprunt TIMESTAMP DEFAULT NOW(),
      date_echeance DATE NOT NULL,
      montant_rembourse DECIMAL(12,2) DEFAULT 0,
      statut VARCHAR(20) DEFAULT 'en_cours',
      approuve_par JSONB DEFAULT '[]'
    );

    CREATE TABLE IF NOT EXISTS notifications (
      id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      utilisateur_id UUID REFERENCES utilisateurs(id),
      tontine_id UUID REFERENCES tontines(id),
      type VARCHAR(50) NOT NULL,
      titre VARCHAR(200),
      message TEXT NOT NULL,
      message_moore TEXT,
      message_dioula TEXT,
      canal VARCHAR(20) DEFAULT 'push',
      est_lu BOOLEAN DEFAULT false,
      envoye_at TIMESTAMP,
      created_at TIMESTAMP DEFAULT NOW()
    );

    CREATE TABLE IF NOT EXISTS notifications_admin (
      id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      titre VARCHAR(200) NOT NULL,
      message_fr TEXT NOT NULL,
      message_moore TEXT,
      message_dioula TEXT,
      destinataires VARCHAR(50) NOT NULL,
      canal VARCHAR(50) NOT NULL,
      nb_envoyes INTEGER DEFAULT 0,
      taux_lecture DECIMAL(5,2) DEFAULT 0,
      envoye_par UUID REFERENCES utilisateurs(id),
      created_at TIMESTAMP DEFAULT NOW()
    );

    CREATE TABLE IF NOT EXISTS adhesions_tontine (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tontine_id UUID REFERENCES tontines(id) ON DELETE CASCADE,
  demandeur_id UUID REFERENCES utilisateurs(id),
  statut VARCHAR(20) DEFAULT 'en_attente',
  message TEXT,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(tontine_id, demandeur_id)
);
ALTER TABLE tontines ADD COLUMN IF NOT EXISTS est_public BOOLEAN DEFAULT false;
ALTER TABLE tontines ADD COLUMN IF NOT EXISTS est_publique BOOLEAN DEFAULT false;
ALTER TABLE tontines ADD COLUMN IF NOT EXISTS photo_tontine TEXT;
ALTER TABLE utilisateurs ADD COLUMN IF NOT EXISTS photo_profil TEXT;
ALTER TABLE utilisateurs ADD COLUMN IF NOT EXISTS pays VARCHAR(5) DEFAULT 'BF';
ALTER TABLE utilisateurs ADD COLUMN IF NOT EXISTS indicatif VARCHAR(10) DEFAULT '+226';
  
    CREATE INDEX IF NOT EXISTS idx_cotisations_tontine ON cotisations(tontine_id);
    CREATE INDEX IF NOT EXISTS idx_cotisations_membre ON cotisations(membre_id);
    CREATE INDEX IF NOT EXISTS idx_membres_tontine ON membres_tontine(tontine_id);
    CREATE INDEX IF NOT EXISTS idx_notifications_user ON notifications(utilisateur_id);
  `);

  // Étape 2 — Ajouter les colonnes manquantes si elles n'existent pas
  await client.query(`
    ALTER TABLE utilisateurs ADD COLUMN IF NOT EXISTS role VARCHAR(20) DEFAULT 'user';
  `);

  // Étape 3 — Créer l'index sur role après que la colonne existe
  await client.query(`
    CREATE INDEX IF NOT EXISTS idx_utilisateurs_role ON utilisateurs(role);
  `);

  await creerCompteAdmin(client);
  logger.info('Tables créées / vérifiées avec succès');
}

async function creerCompteAdmin(client) {
  const bcrypt = require('bcryptjs');
  const { rows } = await client.query(
    "SELECT id FROM utilisateurs WHERE role = 'admin' LIMIT 1"
  );
  if (rows.length === 0) {
    const hashedPin = await bcrypt.hash('admin123', 10);
    await client.query(`
      INSERT INTO utilisateurs (nom, prenom, telephone, code_pin, langue, role)
      VALUES ('Admin', 'Tontine BF', 'admin@tontine-bf.com', $1, 'fr', 'admin')
      ON CONFLICT (telephone) DO NOTHING
    `, [hashedPin]);
    logger.info('Compte admin créé : admin@tontine-bf.com / admin123');
  }
}

module.exports = { pool, connectDB };