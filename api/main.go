package main

import (
	"crypto/rsa"
	"crypto/tls"
	"crypto/x509"
	"encoding/base64"
	"encoding/json"
	"encoding/xml"
	"fmt"
	"net/http"
	"os"

	"github.com/crewjam/saml"
	"github.com/crewjam/saml/samlsp"
	"github.com/gorilla/handlers"
	"github.com/gorilla/mux"
)

type UserData struct {
	NameID    string   `json:"nameID"`
	Email     string   `json:"email"`
	Username  string   `json:"username"`
	Groups    []string `json:"groups"`
	SessionID string   `json:"sessionID"`
}

var samlMiddleware *samlsp.Middleware

func main() {
    // Load X.509 certificate and private key from mounted secrets
    keyPair, err := tls.LoadX509KeyPair("/app/certs/tls.crt", "/app/certs/tls.key")
    if err != nil {
        panic(err)
    }
    keyPair.Leaf, err = x509.ParseCertificate(keyPair.Certificate[0])
    if err != nil {
        panic(err)
    }

    // Read IdP metadata from ConfigMap
    idpMetadata, err := os.ReadFile("/app/config/idp-metadata.xml")
    if err != nil {
        panic(err)
    }

    idpMetadataStruct := &saml.EntityDescriptor{}
    err = xml.Unmarshal(idpMetadata, idpMetadataStruct)
    if err != nil {
        panic(err)
    }

    rootURL := "https://k8s-demo.local"

    opts := samlsp.Options{
        URL:               rootURL,
        Key:              keyPair.PrivateKey.(*rsa.PrivateKey),
        Certificate:      keyPair.Leaf,
        IDPMetadata:      idpMetadataStruct,
        AllowIDPInitiated: true,
    }

    // ... rest of your code remains the same ...

    corsHandler := handlers.CORS(
        handlers.AllowedOrigins([]string{"https://k8s-demo.local"}),
        handlers.AllowedMethods([]string{"GET", "POST", "OPTIONS"}),
        handlers.AllowedHeaders([]string{"Content-Type"}),
        handlers.AllowCredentials(),
    )

    server := &http.Server{
        Addr:    ":8000",
        Handler: corsHandler(r),
    }

    server.ListenAndServe()
}

func getUserInfo(w http.ResponseWriter, r *http.Request) {
	session := samlMiddleware.Session.GetSession(r)
	if session == nil {
		http.Error(w, "Unauthorized", http.StatusUnauthorized)
		return
	}

	claims := session.(samlsp.SessionWithAttributes)

	userData := UserData{
		NameID:    claims.NameID,
		Email:     claims.GetAttribute("email"),
		Username:  claims.GetAttribute("username"),
		Groups:    claims.GetAttributes("groups"),
		SessionID: base64.StdEncoding.EncodeToString(session.ID()),
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(userData)
}

func handleLogout(w http.ResponseWriter, r *http.Request) {
	samlMiddleware.Session.DeleteSession(w, r)
	w.WriteHeader(http.StatusOK)
}
