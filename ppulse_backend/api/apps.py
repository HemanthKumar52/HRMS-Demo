import threading

from django.apps import AppConfig


class ApiConfig(AppConfig):
    name = 'api'

    def ready(self):
        # Warm up face recognition model in a background thread
        # so the first face verification request is fast (~100ms vs ~2.5s).
        def _warmup():
            try:
                from .face_verification import warmup

                warmup()
            except Exception:
                pass

        threading.Thread(target=_warmup, daemon=True).start()
